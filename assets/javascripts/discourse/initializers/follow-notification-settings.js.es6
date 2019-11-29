import { withPluginApi } from "discourse/lib/plugin-api"

export default {
	name: "follow-notification-settings",

	initialize() {
		if(!Discourse.SiteSettings.discourse_follow_enabled)
            return;

		withPluginApi("0.8.24", api => {
			api.modifyClass("controller:preferences/notifications", {
				actions: {
					save() {
						this.get("saveAttrNames").push("custom_fields")
						this._super()
					}
				}
			})
		})
	}
}