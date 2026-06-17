// app/javascript/controllers/membership_type_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "parentSelector", "partnerSelector", "parentSelect", "partnerSelect"]

  connect() {
    this.toggle()
  }

  toggle() {
    const value = this.typeSelectTarget.value

    // Reset: hide both wrappers, disable both selects so they don't submit
    this.parentSelectorTarget.style.display  = "none"
    this.partnerSelectorTarget.style.display = "none"
    this.parentSelectTarget.disabled  = true
    this.partnerSelectTarget.disabled = true

    if (value === "birth") {
      this.parentSelectorTarget.style.display = "block"
      this.parentSelectTarget.disabled = false
    } else if (value === "marriage") {
      this.partnerSelectorTarget.style.display = "block"
      this.partnerSelectTarget.disabled = false
    }
  }
}