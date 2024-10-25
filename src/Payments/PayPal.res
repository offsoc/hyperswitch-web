open RecoilAtoms

module Loader = {
  @react.component
  let make = () => {
    <div className="w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600">
      <Icon size=32 name="loader" />
    </div>
  }
}
let payPalIcon = <Icon size=35 width=90 name="paypal" />

@react.component
let make = () => {
  let loggerState = Recoil.useRecoilValueFromAtom(loggerAtom)
  let (paypalClicked, setPaypalClicked) = React.useState(_ => false)
  let sdkHandleIsThere = Recoil.useRecoilValueFromAtom(isPaymentButtonHandlerProvidedAtom)
  let {publishableKey} = Recoil.useRecoilValueFromAtom(keys)
  let options = Recoil.useRecoilValueFromAtom(optionAtom)
  let areOneClickWalletsRendered = Recoil.useSetRecoilState(areOneClickWalletsRendered)
  let paymentMethodListValue = Recoil.useRecoilValueFromAtom(PaymentUtils.paymentMethodListValue)

  let (_, _, labelType) = options.wallets.style.type_
  let _label = switch labelType {
  | Paypal(val) => val->PaypalSDKTypes.getLabel
  | _ => Paypal->PaypalSDKTypes.getLabel
  }
  let (_, _, heightType, _) = options.wallets.style.height
  let height = switch heightType {
  | Paypal(val) => val
  | _ => 48
  }
  let (buttonColor, textColor) =
    options.wallets.style.theme == Light ? ("#0070ba", "#ffffff") : ("#ffc439", "#000000")
  let isGuestCustomer = UtilityHooks.useIsGuestCustomer()
  let isManualRetryEnabled = Recoil.useRecoilValueFromAtom(RecoilAtoms.isManualRetryEnabled)

  let intent = PaymentHelpers.usePaymentIntent(Some(loggerState), Paypal)
  UtilityHooks.useHandlePostMessages(
    ~complete=paypalClicked,
    ~empty=!paypalClicked,
    ~paymentType="paypal",
  )
  let onPaypalClick = _ev => {
    loggerState.setLogInfo(
      ~value="Paypal Button Clicked",
      ~eventName=PAYPAL_FLOW,
      ~paymentMethod="PAYPAL",
    )
    setPaypalClicked(_ => true)
    open Promise
    Utils.makeOneClickHandlerPromise(sdkHandleIsThere)
    ->then(result => {
      let result = result->JSON.Decode.bool->Option.getOr(false)
      if result {
        let (connectors, _) =
          paymentMethodListValue->PaymentUtils.getConnectors(Wallets(Paypal(Redirect)))
        let body = PaymentBody.paypalRedirectionBody(~connectors)

        let modifiedPaymentBody = PaymentUtils.appendedCustomerAcceptance(
          ~isGuestCustomer,
          ~paymentType=paymentMethodListValue.payment_type,
          ~body,
        )

        intent(
          ~bodyArr=modifiedPaymentBody,
          ~confirmParam={
            return_url: options.wallets.walletReturnUrl,
            publishableKey,
          },
          ~handleUserError=true,
          ~manualRetry=isManualRetryEnabled,
        )
      } else {
        setPaypalClicked(_ => false)
      }
      resolve()
    })
    ->ignore
  }

  React.useEffect0(() => {
    areOneClickWalletsRendered(prev => {
      ...prev,
      isPaypal: true,
    })
    None
  })

  <button
    style={
      display: "inline-block",
      color: textColor,
      height: `${height->Int.toString}px`,
      borderRadius: `${options.wallets.style.buttonRadius->Int.toString}px`,
      width: "100%",
      backgroundColor: buttonColor,
    }
    onClick={_ => options.readOnly ? () : onPaypalClick()}>
    <div className="justify-center" style={display: "flex", flexDirection: "row", color: textColor}>
      {if !paypalClicked {
        payPalIcon
      } else {
        <Loader />
      }}
    </div>
  </button>
}

let default = make
