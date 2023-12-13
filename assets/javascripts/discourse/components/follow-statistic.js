import Component from "@ember/component";
import { schedule } from "@ember/runloop";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: "follow-statistic",

  init() {
    this._super();
    this.set("tagName", this.get("isCard") ? "h3" : "div");
  },

  didInsertElement() {
    this._super(...arguments);
    schedule("afterRender", () => {
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
