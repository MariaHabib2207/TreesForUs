import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)

import MembershipTypeController from "controllers/membership_type_controller"
application.register("membership-type", MembershipTypeController)