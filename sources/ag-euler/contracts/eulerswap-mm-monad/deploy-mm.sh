#!/bin/zsh
# The shMON vaults' own market maker on Monad, Euler side (Root 2026-11-06: "Push it to production ... use our keys to
# run the vault admin safe and the deployer"). The AlphaGrowth deployer deploys:
#   1. EulerSwap v2 (Euler has not deployed it on Monad): protocol fee config (admin = AlphaGrowth Safe), management,
#      implementation, factory, periphery
#   2. our WMON lending vault on the shMON/USDC router: kinky rate curve 20% at no use / 30% at the 90% kink, 116M WMON
#      supply cap, 104M borrow cap, lends 97/98 against eshMON-4 and 79/80 against eUSDC-24, 10% fee, 15% discount
#   3. an unstaking shMON vault (ushMON) for each of the two vaults' exit desks (the desk is its operator), against
#      shMonad's own unstake; the WMON vault lends 97/98 against each
#   4. hands the WMON vault to the AlphaGrowth Safe
# The router side (pricing WMON and resolving the new vaults) is the Safe's: safe-payloads/monad-shmon-usdc-caps-rate.json.
#
#   RPC=<url> zsh deploy-mm.sh deploy     # signs with the `dev` keystore; resumable (reads before it writes)
#   RPC=<url> zsh deploy-mm.sh verify     # read-only checks
#   RPC=<url> zsh deploy-mm.sh scan       # verify every source on MonadScan
# Addresses go to deployed-<chainId>.env (deployed-<chainId>-fork.env on a fork).
set -u
HERE=${0:A:h}
R=${RPC:?set RPC}
CHAIN=$(cast chain-id -r $R)
TAG=""; cast rpc anvil_nodeInfo -r $R >/dev/null 2>&1 && TAG="-fork"
STATE=$HERE/deployed-$CHAIN$TAG.env
KS=(--keystore $HOME/.foundry/keystores/dev --password-file $HOME/.foundry/keystores/dev.pw)
DEP=0x501107fe590c8F9b81c00b81867fD19e0d9c0253

SAFE=0x4f894Bfc9481110278C356adE1473eBe2127Fd3C            # AlphaGrowth Euler Safe
EVC=0x7a9324E8f270413fa2E458f5831226d99C7477CD
EVAULT_FACTORY=0xba4Dd672062dE8FeeDb665DD4410658864483f1E
KINKY_FACTORY=0x3512f50B3f0cA8725CcCBb6DDcc7307Ed2c17feb
PM=0x188d586Ddcf52439676Ca21A244753fA19F9Ea8e               # Uniswap v4 PoolManager
ROUTER=0x52d30dbf4e3209F2666982A47e216e0aA3D9518e           # our shMON/USDC router
ESHMON4=0x2f22C096651BBc97e63B459a561f2416b2F33e81
EUSDC24=0xdE5870224123d974258Ce4501c8b045375d2054a
WMON=0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A
SHMON=0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c
USD=0x0000000000000000000000000000000000000348
DESK_USDC=0x02Df7fb3b4535361EE10C391e3bDDAEe9001c770        # shmon-neverland-usdc-hl exit desk
DESK_USDT0=0x5fa67Eca5a99f85Aa95b2dF61fCF4F27Ce643d7c       # shmon-neverland-usdt0-hl exit desk
IRM_ARGS=(5781378640092421120 656618015 5 3865470565 12857214234784512000) # 20% at 0, 30% at the 90% kink, 50% at 100%
CAPS=(7450 6682)                                           # 116M WMON supply, 104M borrow (Euler AmountCap)
Z=0x0000000000000000000000000000000000000000

num() { awk '{print $1}'; }
# sends run inside $(...), so the next nonce lives in a file, not a shell variable (Monad RPCs lag on pending nonces)
NFILE=$STATE.nonce
next_nonce() { local n; n=$(cat $NFILE 2>/dev/null); [ -n "$n" ] || n=$(cast nonce $DEP --block pending -r $R); print $n; }
save() { print -r -- "$1=$2" >> $STATE; }
need_ok() { [ "$1" = OK ] || { print -u2 "step failed: $2"; exit 1; } }
wait_rc() { # receipt polled by hash, never resent
  local h=$1 i st
  for i in {1..60}; do
    st=$(cast receipt $h status -r $R 2>/dev/null)
    [ -n "$st" ] && { [[ "$st" == 1* ]] && print OK || print REVERTED; return; }
    sleep 2
  done
  print -u2 "  $h not mined after 120s"; print FAILED
}
send() { # Monad bills the gas limit: each send uses its own estimate plus 20%
  local NONCE=$(next_nonce)
  local est=$(cast estimate "$@" --from $DEP -r $R 2>/dev/null) || { print -u2 "  estimate failed: $*"; print FAILED; return; }
  local out=$(cast send "$@" --gas-limit $((est * 12 / 10)) --nonce $NONCE $KS -r $R --async 2>&1)
  local h=$(print -r -- "$out" | grep -oE '0x[0-9a-fA-F]{64}' | head -1)
  [ -n "$h" ] || { print -u2 "  send failed: $(print -r -- "$out" | tail -1 | cut -c1-200)"; print FAILED; return; }
  print $((NONCE + 1)) > $NFILE; wait_rc $h
}
create() { # create <NAME> <artifact> [constructor sig] [args...]: deploys from this project's build, records the address
  local name=$1 art=$2; shift 2
  local cur=${(P)name:-}
  [ -n "$cur" ] && { print "  $name already $cur"; return; }
  local code=$(python3 -c "import json;print(json.load(open('$HERE/out/$art.sol/$art.json'))['bytecode']['object'])")
  [ $# -gt 0 ] && code=$code${$(cast abi-encode "$@")#0x}
  local NONCE=$(next_nonce)
  local addr=$(cast compute-address $DEP --nonce $NONCE | awk '{print $NF}')
  local est=$(cast estimate --from $DEP -r $R --create $code 2>/dev/null) || { print -u2 "  estimate failed: $name"; exit 1; }
  local out=$(cast send --gas-limit $((est * 12 / 10)) --nonce $NONCE $KS -r $R --async --create $code 2>&1)
  local h=$(print -r -- "$out" | grep -oE '0x[0-9a-fA-F]{64}' | head -1)
  [ -n "$h" ] || { print -u2 "  send failed: $(print -r -- "$out" | tail -1 | cut -c1-200)"; exit 1; }
  print $((NONCE + 1)) > $NFILE
  need_ok $(wait_rc $h) "create $name"
  save $name $addr; typeset -g $name=$addr; print "  $name $addr"
}
set_if() { # set_if <contract> <getter sig>[|arg,...] <want> <setter sig> <args...>
  local c=$1 g=$2 want=$3 s=$4; shift 4
  local gargs=(); [[ "$g" == *\|* ]] && { gargs=(${(s:,:)${g#*|}}); g=${g%%|*}; }
  local cur=$(cast call $c "$g" $gargs -r $R 2>/dev/null | num | tr '\n' ' ')
  if [[ "$cur" == "$want "* ]]; then print "  ${s%%\(*} already $want"; return 0; fi
  local st=$(send $c "$s" "$@"); print "  ${s%%\(*} $want: $st"; [ "$st" = OK ]
}

deploy() {
  print "deployer $DEP on chain $CHAIN, $(cast balance $DEP -r $R --ether) MON"
  [ "$(cast wallet address $KS)" = "$DEP" ] || { print -u2 "dev keystore is not $DEP"; exit 1; }
  [ -f $STATE ] && source $STATE
  rm -f $NFILE # start from the chain's own count each run
  print "1. EulerSwap v2"
  create ES_FEE_CONFIG EulerSwapProtocolFeeConfig "constructor(address,address)" $EVC $SAFE
  create ES_MANAGEMENT EulerSwapManagement "constructor(address)" $EVC
  create ES_IMPL EulerSwap "constructor(address,address,address,address)" $EVC $ES_FEE_CONFIG $PM $ES_MANAGEMENT
  create ES_FACTORY EulerSwapFactory "constructor(address,address)" $EVC $ES_IMPL
  create ES_PERIPHERY EulerSwapPeriphery
  print "2. WMON vault"
  if [ -z "${WMON_VAULT:-}" ]; then
    local trail=$(cast concat-hex $WMON $ROUTER $USD)
    local v=$(cast call $EVAULT_FACTORY 'createProxy(address,bool,bytes)(address)' $Z true $trail --from $DEP -r $R)
    need_ok $(send $EVAULT_FACTORY 'createProxy(address,bool,bytes)' $Z true $trail) "create WMON vault"
    [ "$(cast call $v 'asset()(address)' -r $R)" = "$WMON" ] || { print -u2 "WMON vault at $v has the wrong asset"; exit 1; }
    save WMON_VAULT $v; WMON_VAULT=$v; print "  WMON_VAULT $v ($(cast call $v 'symbol()(string)' -r $R))"
  fi
  if [ -z "${WMON_IRM:-}" ]; then
    local irm=$(cast call $KINKY_FACTORY 'deploy(uint256,uint256,uint256,uint32,uint256)(address)' $IRM_ARGS --from $DEP -r $R)
    need_ok $(send $KINKY_FACTORY 'deploy(uint256,uint256,uint256,uint32,uint256)' $IRM_ARGS) "rate curve"
    save WMON_IRM $irm; WMON_IRM=$irm; print "  WMON_IRM $irm"
  fi
  local W=$WMON_VAULT
  [ "$(cast call $W 'governorAdmin()(address)' -r $R)" = "$SAFE" ] && { print "  WMON vault already with the Safe"; } || {
    set_if $W 'interestRateModel()(address)' $WMON_IRM 'setInterestRateModel(address)' $WMON_IRM || exit 1
    set_if $W 'caps()(uint16,uint16)' "${CAPS[1]}" 'setCaps(uint16,uint16)' $CAPS || exit 1
    set_if $W "LTVBorrow(address)(uint16)|$ESHMON4" 9700 'setLTV(address,uint16,uint16,uint32)' $ESHMON4 9700 9800 0 || exit 1
    set_if $W "LTVBorrow(address)(uint16)|$EUSDC24" 7900 'setLTV(address,uint16,uint16,uint32)' $EUSDC24 7900 8000 0 || exit 1
    set_if $W 'interestFee()(uint16)' 1000 'setInterestFee(uint16)' 1000 || exit 1
    set_if $W 'maxLiquidationDiscount()(uint16)' 1500 'setMaxLiquidationDiscount(uint16)' 1500 || exit 1
    set_if $W 'liquidationCoolOffTime()(uint16)' 1 'setLiquidationCoolOffTime(uint16)' 1 || exit 1
    set_if $W 'feeReceiver()(address)' $SAFE 'setFeeReceiver(address)' $SAFE || exit 1
    if [ "$(cast call $W 'hookConfig()(address,uint32)' -r $R | tail -1)" != 0 ]; then
      local st=$(send $W 'setHookConfig(address,uint32)' $Z 0); print "  setHookConfig (open every operation): $st"; [ "$st" = OK ] || exit 1
    else print "  hooks already off"; fi
    print "3. unstaking shMON vaults (operator = each exit desk)"
    create USHMON_USDC_HL UnstakingShMonVault "constructor(address,address,address,address,address)" $EVC $SHMON $SHMON $WMON $DESK_USDC
    create USHMON_USDT0_HL UnstakingShMonVault "constructor(address,address,address,address,address)" $EVC $SHMON $SHMON $WMON $DESK_USDT0
    set_if $W "LTVBorrow(address)(uint16)|$USHMON_USDC_HL" 9700 'setLTV(address,uint16,uint16,uint32)' $USHMON_USDC_HL 9700 9800 0 || exit 1
    set_if $W "LTVBorrow(address)(uint16)|$USHMON_USDT0_HL" 9700 'setLTV(address,uint16,uint16,uint32)' $USHMON_USDT0_HL 9700 9800 0 || exit 1
    print "4. hand the WMON vault to the Safe"
    need_ok $(send $W 'setGovernorAdmin(address)' $SAFE) "governor"
  }
  verify
}

verify() {
  source $STATE
  local bad=0
  chk() { if [ "$2" = "$3" ]; then print "  ok   $1"; else print "  FAIL $1: $2 (want $3)"; bad=1; fi; }
  local W=$WMON_VAULT
  chk "WMON vault asset" "$(cast call $W 'asset()(address)' -r $R)" $WMON
  chk "WMON vault governor = Safe" "$(cast call $W 'governorAdmin()(address)' -r $R)" $SAFE
  chk "WMON vault rate curve" "$(cast call $W 'interestRateModel()(address)' -r $R)" $WMON_IRM
  chk "WMON vault caps" "$(cast call $W 'caps()(uint16,uint16)' -r $R | tr '\n' ' ')" "${CAPS[1]} ${CAPS[2]} "
  chk "WMON vault hooks off" "$(cast call $W 'hookConfig()(address,uint32)' -r $R | tail -1)" 0
  for c in $ESHMON4 $USHMON_USDC_HL $USHMON_USDT0_HL; do chk "LTV vs $c" "$(cast call $W 'LTVBorrow(address)(uint16)' $c -r $R)" 9700; done
  chk "LTV vs eUSDC-24" "$(cast call $W 'LTVBorrow(address)(uint16)' $EUSDC24 -r $R)" 7900
  chk "ushMON (usdc-hl) operator" "$(cast call $USHMON_USDC_HL 'operator()(address)' -r $R)" $DESK_USDC
  chk "ushMON (usdt0-hl) operator" "$(cast call $USHMON_USDT0_HL 'operator()(address)' -r $R)" $DESK_USDT0
  chk "ushMON unstakes through shMonad" "$(cast call $USHMON_USDC_HL 'unstaker()(address)' -r $R)" $SHMON
  chk "EulerSwap factory implementation" "$(cast call $ES_FACTORY 'eulerSwapImpl()(address)' -r $R)" $ES_IMPL
  [ $bad = 0 ] && print "verify: all OK" || { print "verify: FAILED"; exit 1; }
}

scan() { # verify the source of every contract on MonadScan (Etherscan v2 API, chain 143)
  source $STATE
  local KEY=$(grep '^ETHERSCAN_API_KEY=' $HERE/../../.env | cut -d= -f2- | tr -d '"')
  v() { local addr=$1 id=$2; shift 2
    local args=(); [ $# -gt 0 ] && args=(--constructor-args $(cast abi-encode "$@"))
    local res=$(cd $HERE && forge verify-contract $addr $id $args --verifier etherscan --verifier-url 'https://api.etherscan.io/v2/api?chainid=143' --etherscan-api-key $KEY --watch 2>&1 | grep -E "Pass - Verified|already verified|Fail" | head -1)
    print "  ${id##*:} $addr: ${res:-no answer}"; }
  v $ES_FEE_CONFIG src/EulerSwapProtocolFeeConfig.sol:EulerSwapProtocolFeeConfig "constructor(address,address)" $EVC $SAFE
  v $ES_MANAGEMENT src/EulerSwapManagement.sol:EulerSwapManagement "constructor(address)" $EVC
  v $ES_IMPL src/EulerSwap.sol:EulerSwap "constructor(address,address,address,address)" $EVC $ES_FEE_CONFIG $PM $ES_MANAGEMENT
  v $ES_FACTORY src/EulerSwapFactory.sol:EulerSwapFactory "constructor(address,address)" $EVC $ES_IMPL
  v $ES_PERIPHERY src/EulerSwapPeriphery.sol:EulerSwapPeriphery
  v $USHMON_USDC_HL src/exitmm/UnstakingShMonVault.sol:UnstakingShMonVault "constructor(address,address,address,address,address)" $EVC $SHMON $SHMON $WMON $DESK_USDC
  v $USHMON_USDT0_HL src/exitmm/UnstakingShMonVault.sol:UnstakingShMonVault "constructor(address,address,address,address,address)" $EVC $SHMON $SHMON $WMON $DESK_USDT0
}

case ${1:-} in
  deploy) deploy ;;
  verify) verify ;;
  scan) scan ;;
  *) print -u2 "usage: RPC=<url> zsh deploy-mm.sh deploy|verify"; exit 1 ;;
esac
