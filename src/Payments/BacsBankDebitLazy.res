open LazyUtils

@obj
external makeProps: (
  ~paymentType: CardThemeType.mode,
  ~list: PaymentMethodsRecord.list,
  unit,
) => componentProps = ""

let make = reactLazy(.() => import_("./BacsBankDebit.bs.js"))