#!/bin/zsh
# A new shMON Euler cluster on Monad that we own while it is built and tested, then hand to AlphaGrowth (Root
# 2026-11-06: "build a new cluster entirely that is exactly as we need it, and then own it entirely, make sure its build
# correct, and then sign that cluster over to alphagrowth, and then let that one be the official version").
# It merges ../shmon-usdc-monad/deploy.sh (router, shMON and USDC vaults) and ../eulerswap-mm-monad/deploy-mm.sh (WMON
# vault, unstaking shMON vaults), with every setting copied from them and from the AlphaGrowth Safe batch they waited on
# (safe-payloads/monad-shmon-usdc-caps-rate.json). The EulerSwap v2 contracts already deployed by deploy-mm.sh are reused.
#   cluster   router, shMON collateral vault, USDC, WMON and USDT0 lending vaults, every setting; the dev deployer
#             stays governor
#   desks     one unstaking shMON vault per exit desk: DESKS="name=0xdesk,name=0xdesk" (the desk is its operator); the
#             router resolves it and the WMON vault lends 97/98 against it
#   handover  every vault's governor and the router's governor become the AlphaGrowth Safe
#   verify    read-only checks (HANDED=1 also checks the handover)
#   RPC=<url> zsh deploy.sh cluster|desks|handover|verify       (signs with the `dev` keystore; every step reads first)
# Addresses go to deployed-<chainId>.env (deployed-<chainId>-fork.env on a fork).
set -u
HERE=${0:A:h}
R=${RPC:?set RPC}
CHAIN=$(cast chain-id -r $R)
TAG=""; cast rpc anvil_nodeInfo -r $R >/dev/null 2>&1 && TAG="-fork"
STATE=$HERE/deployed-$CHAIN$TAG.env
KS=(--keystore $HOME/.foundry/keystores/dev --password-file $HOME/.foundry/keystores/dev.pw)
DEP=0x501107fe590c8F9b81c00b81867fD19e0d9c0253
USH_ART=$HERE/../eulerswap-mm-monad/out/UnstakingShMonVault.sol/UnstakingShMonVault.json

# ---- live on Monad 143 -------------------------------------------------------------------------------------------------
SAFE=0x4f894Bfc9481110278C356adE1473eBe2127Fd3C            # AlphaGrowth Euler Safe: fee receiver now, governor after handover
EVC=0x7a9324E8f270413fa2E458f5831226d99C7477CD
EVAULT_FACTORY=0xba4Dd672062dE8FeeDb665DD4410658864483f1E
ROUTER_FACTORY=0xdDA3cBC18e90606A83FBae6F798991af06dFA902
USD=0x0000000000000000000000000000000000000348
USDC=0x754704Bc059F8C67012fEd69BC8A327a5aafb603
SHMON=0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c
WMON=0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A
USDT0=0xe7cd86e13AC4309349F30B3435a9d337750fC82D            # 6 decimals
# Chainlink SVR feeds (Root 2026-11-12 "our oracles will be chainlink SVR"): Euler ChainlinkOracle / CrossAdapter
# adapters built from euler-xyz/euler-price-oracle 63f20a4, byte for byte Euler's live adapters but the metadata tail,
# rehearsed on a fork, set on the router 2026-11-12. The feeds move on 5 bps and arrive one block after the plain
# feeds; the value searchers take from liquidations against them is shared back to the reading protocol.
SHMON_USD=0x2B435c1D99A8D1667838d7d9a9d1636849E3eAB6         # CrossAdapter shMON/WMON (0x0A75…6c6C, shMON/MON SVR rate, 25h) x WMON/USD
USDC_USD=0x74594f3CAc8B43DAF148c8ff5323C40440F18284          # ChainlinkOracle USDC/USD SVR 0x30cF…7E50, 2h
MON_USD=0xe6a6243E10C3D01b723bC806Da0226425dc0fB9d           # ChainlinkOracle WMON/USD on MON/USD SVR 0xFB50…8015, 2h
USDT0_USD=0xBD48e8B62d39C2d3337A342Fd70Ef8ACD173519F         # ChainlinkOracle USDT0/USD SVR 0x731E…765e, 2h
# the first set, until 2026-11-12: shMON 0xFD8db30cE78b019700861F21F3b44117c0A2e000 (RedStone cross), USDC
# 0x922d28eEa3f3946c098bF6b216459AE783bf13FF (RedStone), MON 0x03e574FAD8b74FE9DA7F32d709bD881A6e8eF2dE (RedStone, for WMON),
# USDT0 0x2D842527F1E6CD19a643C127B175bb80924B3036 (ChainlinkOracle, 2h; still in eUSDT0-2 to -9 and -11's routers)
USDC_IRM=0xe743F06a8A2Dcc9565926a9b11513e957e1897c6          # the kinked USDC curve the Safe batch set on eUSDC-24
WMON_IRM=0xa359026aae6c26Ba90B3D3AB78Fc483Da09DBa8a          # deploy-mm.sh's WMON curve: 20% at 0, 30% at the 90% kink

# ---- settings, copied ----------------------------------------------------------------------------------------------------
SHMON_CAP=12826                                            # the Safe batch's eshMON-4 cap
USDC_CAPS=(23053 20749)                                    # 36M USDC supply / 32.4M borrow
WMON_CAPS=(7450 6682)                                      # 116M WMON supply / 104M borrow
LTV_USDC=(7900 8000)                                       # USDC lends 79/80 against shMON and against WMON shares
LTV_WMON_SH=(9700 9800)         # WMON lends 97/98 against shMON
LTV_WMON_USH=(9300 9500)        # WMON lends 93/95 against unstaking shMON (Root 2026-11-16: "move to 93/95 now. It's built for external lenders.")
LTV_WMON_USDC=(7900 8000)                                  # WMON lends 79/80 against USDC shares
# the USDT0 vault, for the USDC/USDT0 EulerSwap pool, paired with the USDC vault (Root 2026-11-06: "Yes, connected to the main USDC pool.")
USDT0_IRM=$USDC_IRM                                        # the same kinked stable curve as USDC
USDT0_CAPS=(23053 20749)                                   # 36M supply / 32.4M borrow, as USDC
LTV_STABLE=(9500 9600)                                     # USDC lends against USDT0 shares, and USDT0 against USDC shares
FEE=1000; LIQ_DISCOUNT=1500; COOL_OFF=1
Z=0x0000000000000000000000000000000000000000

num() { awk '{print $1}'; }
NFILE=$STATE.nonce
next_nonce() { local n; n=$(cat $NFILE 2>/dev/null); [ -n "$n" ] || n=$(cast nonce $DEP --block pending -r $R); print $n; }
save() { print -r -- "$1=$2" >> $STATE; }
need_ok() { [ "$1" = OK ] || { print -u2 "step failed: $2"; exit 1; } }
wait_rc() { local h=$1 i st
  for i in {1..60}; do
    st=$(cast receipt $h status -r $R 2>/dev/null)
    [ -n "$st" ] && { [[ "$st" == 1* ]] && print OK || print REVERTED; return; }
    sleep 2
  done
  print -u2 "  $h not mined after 120s"; print FAILED
}
send() { # Monad bills the gas limit: each send uses its own estimate plus 20%; one broadcast, never resent
  local NONCE=$(next_nonce)
  local est=$(cast estimate "$@" --from $DEP -r $R 2>/dev/null) || { print -u2 "  estimate failed: $*"; print FAILED; return; }
  local out=$(cast send "$@" --gas-limit $((est * 12 / 10)) --nonce $NONCE $KS -r $R --async 2>&1)
  local h=$(print -r -- "$out" | grep -oE '0x[0-9a-fA-F]{64}' | head -1)
  [ -n "$h" ] || { print -u2 "  send failed: $(print -r -- "$out" | tail -1 | cut -c1-200)"; print FAILED; return; }
  print $((NONCE + 1)) > $NFILE; wait_rc $h
}
wait_code() { local i; for i in {1..30}; do [ "$(cast codesize $1 -r $R 2>/dev/null)" -gt 0 ] 2>/dev/null && return 0; sleep 2; done; return 1; }
set_if() { # set_if <contract> <getter sig>[|arg,...] <want> <setter sig> <args...>: reads first, sends only when it differs
  local c=$1 g=$2 want=$3 s=$4; shift 4
  local gargs=(); [[ "$g" == *\|* ]] && { gargs=(${(s:,:)${g#*|}}); g=${g%%|*}; }
  local cur=$(cast call $c "$g" $gargs -r $R 2>/dev/null | num | tr '\n' ' ')
  if [[ "$cur" == "$want "* ]]; then print "  ${s%%\(*} already $want"; return 0; fi
  local st=$(send $c "$s" "$@"); print "  ${s%%\(*} $want: $st"; [ "$st" = OK ]
}
begin() {
  print "deployer $DEP on chain $CHAIN$TAG, $(cast balance $DEP -r $R --ether) MON"
  [ "$(cast wallet address $KS)" = "$DEP" ] || { print -u2 "dev keystore is not $DEP"; exit 1; }
  [ -f $STATE ] && source $STATE
  rm -f $NFILE
}
evault() { # evault <NAME> <asset>
  local name=$1 asset=$2
  [ -n "${(P)name:-}" ] && { print "  $name ${(P)name} already recorded"; return; }
  local trail=$(cast concat-hex $asset $ROUTER $USD)
  local v=$(cast call $EVAULT_FACTORY 'createProxy(address,bool,bytes)(address)' $Z true $trail --from $DEP -r $R)
  need_ok $(send $EVAULT_FACTORY 'createProxy(address,bool,bytes)' $Z true $trail) "create $name"
  wait_code $v; [ "$(cast call $v 'asset()(address)' -r $R)" = "$asset" ] || { print -u2 "$name at $v has the wrong asset"; exit 1; }
  save $name $v; typeset -g $name=$v; print "  $name $v ($(cast call $v 'symbol()(string)' -r $R))"
}
common() { # the settings every vault shares; hooks last, which opens it
  local v=$1
  set_if $v 'maxLiquidationDiscount()(uint16)' $LIQ_DISCOUNT 'setMaxLiquidationDiscount(uint16)' $LIQ_DISCOUNT || exit 1
  set_if $v 'liquidationCoolOffTime()(uint16)' $COOL_OFF 'setLiquidationCoolOffTime(uint16)' $COOL_OFF || exit 1
  set_if $v 'feeReceiver()(address)' $SAFE 'setFeeReceiver(address)' $SAFE || exit 1
  set_if $v 'hookConfig()(address,uint32)' "$Z 0" 'setHookConfig(address,uint32)' $Z 0 || exit 1
}

cluster() {
  begin
  print "1. router"
  if [ -z "${ROUTER:-}" ]; then
    local r=$(cast call $ROUTER_FACTORY 'deploy(address)(address)' $DEP --from $DEP -r $R)
    need_ok $(send $ROUTER_FACTORY 'deploy(address)' $DEP) "router"
    wait_code $r || { print -u2 "router not at $r"; exit 1; }
    save ROUTER $r; ROUTER=$r; print "  ROUTER $r"
  else print "  ROUTER $ROUTER already recorded"; fi
  print "2. vaults"
  evault SHMON_VAULT $SHMON
  evault USDC_VAULT $USDC
  evault WMON_VAULT $WMON
  evault USDT0_VAULT $USDT0
  print "3. prices"
  set_if $ROUTER "getConfiguredOracle(address,address)(address)|$SHMON,$USD" $SHMON_USD 'govSetConfig(address,address,address)' $SHMON $USD $SHMON_USD || exit 1
  set_if $ROUTER "getConfiguredOracle(address,address)(address)|$USDC,$USD" $USDC_USD 'govSetConfig(address,address,address)' $USDC $USD $USDC_USD || exit 1
  set_if $ROUTER "getConfiguredOracle(address,address)(address)|$WMON,$USD" $MON_USD 'govSetConfig(address,address,address)' $WMON $USD $MON_USD || exit 1
  set_if $ROUTER "getConfiguredOracle(address,address)(address)|$USDT0,$USD" $USDT0_USD 'govSetConfig(address,address,address)' $USDT0 $USD $USDT0_USD || exit 1
  for v a in $SHMON_VAULT $SHMON $USDC_VAULT $USDC $WMON_VAULT $WMON $USDT0_VAULT $USDT0; do
    set_if $ROUTER "resolvedVaults(address)(address)|$v" $a 'govSetResolvedVault(address,bool)' $v true || exit 1
  done
  print "4. shMON collateral vault $SHMON_VAULT"
  set_if $SHMON_VAULT 'caps()(uint16,uint16)' "$SHMON_CAP 1" 'setCaps(uint16,uint16)' $SHMON_CAP 1 || exit 1
  common $SHMON_VAULT
  print "5. USDC lending vault $USDC_VAULT"
  set_if $USDC_VAULT 'interestRateModel()(address)' $USDC_IRM 'setInterestRateModel(address)' $USDC_IRM || exit 1
  set_if $USDC_VAULT 'caps()(uint16,uint16)' "$USDC_CAPS" 'setCaps(uint16,uint16)' $USDC_CAPS || exit 1
  set_if $USDC_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$SHMON_VAULT" "$LTV_USDC" 'setLTV(address,uint16,uint16,uint32)' $SHMON_VAULT $LTV_USDC 0 || exit 1
  set_if $USDC_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$WMON_VAULT" "$LTV_USDC" 'setLTV(address,uint16,uint16,uint32)' $WMON_VAULT $LTV_USDC 0 || exit 1
  set_if $USDC_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$USDT0_VAULT" "$LTV_STABLE" 'setLTV(address,uint16,uint16,uint32)' $USDT0_VAULT $LTV_STABLE 0 || exit 1
  set_if $USDC_VAULT 'interestFee()(uint16)' $FEE 'setInterestFee(uint16)' $FEE || exit 1
  common $USDC_VAULT
  print "6. WMON lending vault $WMON_VAULT"
  set_if $WMON_VAULT 'interestRateModel()(address)' $WMON_IRM 'setInterestRateModel(address)' $WMON_IRM || exit 1
  set_if $WMON_VAULT 'caps()(uint16,uint16)' "$WMON_CAPS" 'setCaps(uint16,uint16)' $WMON_CAPS || exit 1
  set_if $WMON_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$SHMON_VAULT" "$LTV_WMON_SH" 'setLTV(address,uint16,uint16,uint32)' $SHMON_VAULT $LTV_WMON_SH 0 || exit 1
  set_if $WMON_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$USDC_VAULT" "$LTV_WMON_USDC" 'setLTV(address,uint16,uint16,uint32)' $USDC_VAULT $LTV_WMON_USDC 0 || exit 1
  set_if $WMON_VAULT 'interestFee()(uint16)' $FEE 'setInterestFee(uint16)' $FEE || exit 1
  common $WMON_VAULT
  print "7. USDT0 lending vault $USDT0_VAULT"
  set_if $USDT0_VAULT 'interestRateModel()(address)' $USDT0_IRM 'setInterestRateModel(address)' $USDT0_IRM || exit 1
  set_if $USDT0_VAULT 'caps()(uint16,uint16)' "$USDT0_CAPS" 'setCaps(uint16,uint16)' $USDT0_CAPS || exit 1
  set_if $USDT0_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$USDC_VAULT" "$LTV_STABLE" 'setLTV(address,uint16,uint16,uint32)' $USDC_VAULT $LTV_STABLE 0 || exit 1
  set_if $USDT0_VAULT 'interestFee()(uint16)' $FEE 'setInterestFee(uint16)' $FEE || exit 1
  common $USDT0_VAULT
  print "cluster built; the deployer is still its governor"
}

desks() {
  begin
  [ -n "${ROUTER:-}" ] || { print -u2 "run cluster first"; exit 1; }
  local code0=$(python3 -c "import json;print(json.load(open('$USH_ART'))['bytecode']['object'])")
  for pair in ${(s:,:)${DESKS:?set DESKS=name=0xdesk,...}}; do
    local name=USHMON_${${pair%%=*}:u} desk=${pair#*=}
    name=${name//-/_}
    if [ -z "${(P)name:-}" ]; then
      local NONCE=$(next_nonce)
      local addr=$(cast compute-address $DEP --nonce $NONCE | awk '{print $NF}')
      local code=$code0${$(cast abi-encode "constructor(address,address,address,address,address)" $EVC $SHMON $SHMON $WMON $desk)#0x}
      local est=$(cast estimate --from $DEP -r $R --create $code 2>/dev/null) || { print -u2 "  estimate failed: $name"; exit 1; }
      local out=$(cast send --gas-limit $((est * 12 / 10)) --nonce $NONCE $KS -r $R --async --create $code 2>&1)
      local h=$(print -r -- "$out" | grep -oE '0x[0-9a-fA-F]{64}' | head -1)
      [ -n "$h" ] || { print -u2 "  send failed: $name"; exit 1; }
      print $((NONCE + 1)) > $NFILE
      need_ok $(wait_rc $h) "create $name"
      save $name $addr; typeset -g $name=$addr
    fi
    local u=${(P)name}
    [ "$(cast call $u 'operator()(address)' -r $R)" = "$desk" ] || { print -u2 "$name at $u is not operated by $desk"; exit 1; }
    print "  $name $u, operated by $desk"
    set_if $ROUTER "resolvedVaults(address)(address)|$u" $SHMON 'govSetResolvedVault(address,bool)' $u true || exit 1
    set_if $WMON_VAULT "LTVFull(address)(uint16,uint16,uint16,uint48,uint32)|$u" "$LTV_WMON_USH" 'setLTV(address,uint16,uint16,uint32)' $u $LTV_WMON_USH 0 || exit 1
  done
}

handover() {
  begin
  print "handing the cluster to the AlphaGrowth Safe $SAFE"
  for v in $SHMON_VAULT $USDC_VAULT $WMON_VAULT $USDT0_VAULT; do
    set_if $v 'governorAdmin()(address)' $SAFE 'setGovernorAdmin(address)' $SAFE || exit 1
  done
  set_if $ROUTER 'governor()(address)' $SAFE 'transferGovernance(address)' $SAFE || exit 1
  HANDED=1 verify
}

verify() {
  source $STATE; local bad=0 gov=$DEP; [ "${HANDED:-0}" = 1 ] && gov=$SAFE
  chk() { if [ "$2" = "$3" ]; then print "  ok   $1"; else print "  FAIL $1: $2 (want $3)"; bad=1; fi; }
  print "router $ROUTER"
  chk "router governor" "$(cast call $ROUTER 'governor()(address)' -r $R)" $gov
  for a f in $SHMON $SHMON_USD $USDC $USDC_USD $WMON $MON_USD $USDT0 $USDT0_USD; do chk "price feed for $a" "$(cast call $ROUTER 'getConfiguredOracle(address,address)(address)' $a $USD -r $R)" $f; done
  for v in $SHMON_VAULT $USDC_VAULT $WMON_VAULT $USDT0_VAULT; do
    print "vault $v ($(cast call $v 'symbol()(string)' -r $R))"
    chk "governor" "$(cast call $v 'governorAdmin()(address)' -r $R)" $gov
    chk "open" "$(cast call $v 'hookConfig()(address,uint32)' -r $R | sed -n 2p | num)" 0
    chk "priced by the router" "$(cast call $v 'oracle()(address)' -r $R)" $ROUTER
    chk "fees to the Safe" "$(cast call $v 'feeReceiver()(address)' -r $R)" $SAFE
    print "  1 share = \$$(cast call $ROUTER 'getQuote(uint256,address,address)(uint256)' $((10 ** $(cast call $v 'decimals()(uint8)' -r $R))) $v $USD -r $R | num | awk '{printf "%.5f", $1/1e18}')"
  done
  chk "shMON vault caps" "$(cast call $SHMON_VAULT 'caps()(uint16,uint16)' -r $R | num | tr '\n' ' ')" "$SHMON_CAP 1 "
  chk "USDC vault caps" "$(cast call $USDC_VAULT 'caps()(uint16,uint16)' -r $R | num | tr '\n' ' ')" "$USDC_CAPS "
  chk "USDC vault rate curve" "$(cast call $USDC_VAULT 'interestRateModel()(address)' -r $R)" $USDC_IRM
  chk "USDC lends 79/80 against shMON" "$(cast call $USDC_VAULT 'LTVFull(address)(uint16,uint16,uint16,uint48,uint32)' $SHMON_VAULT -r $R | num | head -2 | tr '\n' ' ')" "$LTV_USDC "
  chk "WMON vault caps" "$(cast call $WMON_VAULT 'caps()(uint16,uint16)' -r $R | num | tr '\n' ' ')" "$WMON_CAPS "
  chk "WMON vault rate curve" "$(cast call $WMON_VAULT 'interestRateModel()(address)' -r $R)" $WMON_IRM
  chk "WMON lends 97/98 against shMON" "$(cast call $WMON_VAULT 'LTVFull(address)(uint16,uint16,uint16,uint48,uint32)' $SHMON_VAULT -r $R | num | head -2 | tr '\n' ' ')" "$LTV_WMON_SH "
  chk "USDT0 vault caps" "$(cast call $USDT0_VAULT 'caps()(uint16,uint16)' -r $R | num | tr '\n' ' ')" "$USDT0_CAPS "
  chk "USDC lends 95/96 against USDT0" "$(cast call $USDC_VAULT 'LTVFull(address)(uint16,uint16,uint16,uint48,uint32)' $USDT0_VAULT -r $R | num | head -2 | tr '\n' ' ')" "$LTV_STABLE "
  chk "USDT0 lends 95/96 against USDC" "$(cast call $USDT0_VAULT 'LTVFull(address)(uint16,uint16,uint16,uint48,uint32)' $USDC_VAULT -r $R | num | head -2 | tr '\n' ' ')" "$LTV_STABLE "
  for name in ${(k)parameters[(I)USHMON_*]}; do
    local u=${(P)name}
    chk "$name resolved" "$(cast call $ROUTER 'resolvedVaults(address)(address)' $u -r $R)" $SHMON
    chk "WMON lends 93/95 against $name" "$(cast call $WMON_VAULT 'LTVFull(address)(uint16,uint16,uint16,uint48,uint32)' $u -r $R | num | head -2 | tr '\n' ' ')" "$LTV_WMON_USH "
  done
  [ $bad = 0 ] && print "verify: all OK" || { print "verify: FAILED"; exit 1; }
}

case ${1:-} in
  cluster|desks|handover|verify) $1 ;;
  *) print -u2 "usage: RPC=<url> zsh deploy.sh cluster|desks|handover|verify"; exit 2 ;;
esac
