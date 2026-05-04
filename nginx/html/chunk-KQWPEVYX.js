import {
  AuthService,
  Router,
  RouterLink
} from "./chunk-BLNTAYHO.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgControlStatusGroup,
  NgForm,
  NgModel,
  RequiredValidator,
  ɵNgNoValidate
} from "./chunk-TPOCFAFA.js";
import {
  Component,
  inject,
  setClassMetadata,
  ɵsetClassDebugInfo,
  ɵɵadvance,
  ɵɵconditional,
  ɵɵconditionalCreate,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtwoWayBindingSet,
  ɵɵtwoWayListener,
  ɵɵtwoWayProperty
} from "./chunk-UDUTJOOT.js";

// src/app/pages/login/login.ts
function Login_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.error);
  }
}
function Login_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "span", 12);
  }
}
var Login = class _Login {
  auth = inject(AuthService);
  router = inject(Router);
  username = "";
  password = "";
  error = "";
  loading = false;
  submit() {
    if (!this.username || !this.password)
      return;
    this.loading = true;
    this.error = "";
    this.auth.login(this.username, this.password).subscribe({
      next: () => this.router.navigate(["/dashboard"]),
      error: () => {
        this.error = "Usuario o contrase\xF1a incorrectos.";
        this.loading = false;
      }
    });
  }
  static \u0275fac = function Login_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _Login)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _Login, selectors: [["app-login"]], decls: 24, vars: 5, consts: [[1, "min-vh-100", "d-flex", "align-items-center", "justify-content-center"], [1, "card", "shadow", 2, "width", "360px"], [1, "card-body", "p-4"], [1, "card-title", "text-center", "mb-4"], [1, "bi", "bi-journal-richtext", "me-2", "text-primary"], [1, "alert", "alert-danger", "py-2"], [3, "ngSubmit"], [1, "mb-3"], [1, "form-label"], ["name", "username", "required", "", "autofocus", "", 1, "form-control", 3, "ngModelChange", "ngModel"], ["type", "password", "name", "password", "required", "", 1, "form-control", 3, "ngModelChange", "ngModel"], ["type", "submit", 1, "btn", "btn-primary", "w-100", 3, "disabled"], [1, "spinner-border", "spinner-border-sm", "me-2"], [1, "text-center", "mb-0", "small"], ["routerLink", "/register"]], template: function Login_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div", 2)(3, "h4", 3);
      \u0275\u0275element(4, "i", 4);
      \u0275\u0275text(5, "ScienClassifier ");
      \u0275\u0275elementEnd();
      \u0275\u0275conditionalCreate(6, Login_Conditional_6_Template, 2, 1, "div", 5);
      \u0275\u0275elementStart(7, "form", 6);
      \u0275\u0275listener("ngSubmit", function Login_Template_form_ngSubmit_7_listener() {
        return ctx.submit();
      });
      \u0275\u0275elementStart(8, "div", 7)(9, "label", 8);
      \u0275\u0275text(10, "Usuario");
      \u0275\u0275elementEnd();
      \u0275\u0275elementStart(11, "input", 9);
      \u0275\u0275twoWayListener("ngModelChange", function Login_Template_input_ngModelChange_11_listener($event) {
        \u0275\u0275twoWayBindingSet(ctx.username, $event) || (ctx.username = $event);
        return $event;
      });
      \u0275\u0275elementEnd()();
      \u0275\u0275elementStart(12, "div", 7)(13, "label", 8);
      \u0275\u0275text(14, "Contrase\xF1a");
      \u0275\u0275elementEnd();
      \u0275\u0275elementStart(15, "input", 10);
      \u0275\u0275twoWayListener("ngModelChange", function Login_Template_input_ngModelChange_15_listener($event) {
        \u0275\u0275twoWayBindingSet(ctx.password, $event) || (ctx.password = $event);
        return $event;
      });
      \u0275\u0275elementEnd()();
      \u0275\u0275elementStart(16, "button", 11);
      \u0275\u0275conditionalCreate(17, Login_Conditional_17_Template, 1, 0, "span", 12);
      \u0275\u0275text(18, " Iniciar sesi\xF3n ");
      \u0275\u0275elementEnd()();
      \u0275\u0275element(19, "hr");
      \u0275\u0275elementStart(20, "p", 13);
      \u0275\u0275text(21, " \xBFNo tienes cuenta? ");
      \u0275\u0275elementStart(22, "a", 14);
      \u0275\u0275text(23, "Reg\xEDstrate");
      \u0275\u0275elementEnd()()()()();
    }
    if (rf & 2) {
      \u0275\u0275advance(6);
      \u0275\u0275conditional(ctx.error ? 6 : -1);
      \u0275\u0275advance(5);
      \u0275\u0275twoWayProperty("ngModel", ctx.username);
      \u0275\u0275advance(4);
      \u0275\u0275twoWayProperty("ngModel", ctx.password);
      \u0275\u0275advance();
      \u0275\u0275property("disabled", ctx.loading);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.loading ? 17 : -1);
    }
  }, dependencies: [FormsModule, \u0275NgNoValidate, DefaultValueAccessor, NgControlStatus, NgControlStatusGroup, RequiredValidator, NgModel, NgForm, RouterLink], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(Login, [{
    type: Component,
    args: [{ selector: "app-login", imports: [FormsModule, RouterLink], template: '<div class="min-vh-100 d-flex align-items-center justify-content-center">\n  <div class="card shadow" style="width: 360px">\n    <div class="card-body p-4">\n      <h4 class="card-title text-center mb-4">\n        <i class="bi bi-journal-richtext me-2 text-primary"></i>ScienClassifier\n      </h4>\n\n      @if (error) {\n        <div class="alert alert-danger py-2">{{ error }}</div>\n      }\n\n      <form (ngSubmit)="submit()">\n        <div class="mb-3">\n          <label class="form-label">Usuario</label>\n          <input class="form-control" [(ngModel)]="username" name="username" required autofocus />\n        </div>\n        <div class="mb-3">\n          <label class="form-label">Contrase\xF1a</label>\n          <input class="form-control" type="password" [(ngModel)]="password" name="password" required />\n        </div>\n        <button class="btn btn-primary w-100" type="submit" [disabled]="loading">\n          @if (loading) { <span class="spinner-border spinner-border-sm me-2"></span> }\n          Iniciar sesi\xF3n\n        </button>\n      </form>\n\n      <hr />\n      <p class="text-center mb-0 small">\n        \xBFNo tienes cuenta? <a routerLink="/register">Reg\xEDstrate</a>\n      </p>\n    </div>\n  </div>\n</div>\n' }]
  }], null, null);
})();
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(Login, { className: "Login", filePath: "src/app/pages/login/login.ts", lineNumber: 12 });
})();
export {
  Login
};
//# sourceMappingURL=chunk-KQWPEVYX.js.map
