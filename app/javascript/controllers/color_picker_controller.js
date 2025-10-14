import ColorPicker from "@stimulus-components/color-picker"

export default class extends ColorPicker {

  connect() {
    console.log("ColorPicker connected")
    super.connect()


  }
    // You can override the components options with this getter.
  // Here are the default options.
  get componentOptions() {
    return {
      hue: true,

      interaction: {
        input: true,
        clear: false,
        save: true,
      },
    }
  }
}