import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="removals"
export default class extends Controller {
  static targets = ["flash"];

  connect() {
    setTimeout(() => {
      this.element.remove();
    }, 7000);
  }

  remove() {
    this.flashTarget.remove();
    this.element.remove();
  }
}
