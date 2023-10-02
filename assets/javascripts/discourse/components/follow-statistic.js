import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { scheduleOnce } from "@ember/runloop";

export default Component.extend({
  classNames: "follow-statistic",

  init() {
    this._super();
    this.set("tagName", this.get("isCard") ? "h3" : "div");
  },

  didInsertElement() {
    scheduleOnce("afterRender", () => {
      let parent = this.get("isCard")
        ? ".card-content .metadata"
        : ".user-main .secondary dl";
      const parentElement = document.querySelector(parent);
      parentElement.prepend(this.element);
    });
  },

  @discourseComputed("context")
  isCard(context) {
    return context === "card";
  },
});
