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

// src/app/pages/register/register.ts
function Register_Conditional_6_Template(rf, ctx) {
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
function Register_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.success);
  }
}
function Register_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "span", 14);
  }
}
var Register = class _Register {
  auth = inject(AuthService);
  router = inject(Router);
  username = "";
  password = "";
  confirm = "";
  error = "";
  success = "";
  loading = false;
  submit() {
    if (this.password !== this.confirm) {
      this.error = "Las contrase\xF1as no coinciden.";
      return;
    }
    this.loading = true;
    this.error = "";
    this.auth.register(this.username, this.password).subscribe({
      next: () => {
        this.success = "Cuenta creada. Redirigiendo...";
        setTimeout(() => this.router.navigate(["/login"]), 1500);
      },
      error: (e) => {
        this.error = e.error?.detail ?? "Error al registrar.";
        this.loading = false;
      }
    });
  }
  static \u0275fac = function Register_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _Register)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _Register, selectors: [["app-register"]], decls: 29, vars: 7, consts: [[1, "min-vh-100", "d-flex", "align-items-center", "justify-content-center"], [1, "card", "shadow", 2, "width", "380px"], [1, "card-body", "p-4"], [1, "card-title", "text-center", "mb-4"], [1, "bi", "bi-person-plus", "me-2", "text-primary"], [1, "alert", "alert-danger", "py-2"], [1, "alert", "alert-success", "py-2"], [3, "ngSubmit"], [1, "mb-3"], [1, "form-label"], ["name", "username", "required", "", "autofocus", "", 1, "form-control", 3, "ngModelChange", "ngModel"], ["type", "password", "name", "password", "required", "", 1, "form-control", 3, "ngModelChange", "ngModel"], ["type", "password", "name", "confirm", "required", "", 1, "form-control", 3, "ngModelChange", "ngModel"], ["type", "submit", 1, "btn", "btn-primary", "w-100", 3, "disabled"], [1, "spinner-border", "spinner-border-sm", "me-2"], [1, "text-center", "mb-0", "small"], ["routerLink", "/login"]], template: function Register_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div", 2)(3, "h4", 3);
      \u0275\u0275element(4, "i", 4);
      \u0275\u0275text(5, "Crear cuenta ");
      \u0275\u0275elementEnd();
      \u0275\u0275conditionalCreate(6, Register_Conditional_6_Template, 2, 1, "div", 5);
      \u0275\u0275conditionalCreate(7, Register_Conditional_7_Template, 2, 1, "div", 6);
      \u0275\u0275elementStart(8, "form", 7);
      \u0275\u0275listener("ngSubmit", function Register_Template_form_ngSubmit_8_listener() {
        return ctx.submit();
      });
      \u0275\u0275elementStart(9, "div", 8)(10, "label", 9);
      \u0275\u0275text(11, "Usuario");
      \u0275\u0275elementEnd();
      \u0275\u0275elementStart(12, "input", 10);
      \u0275\u0275twoWayListener("ngModelChange", function Register_Template_input_ngModelChange_12_listener($event) {
        \u0275\u0275twoWayBindingSet(ctx.username, $event) || (ctx.username = $event);
        return $event;
      });
      \u0275\u0275elementEnd()();
      \u0275\u0275elementStart(13, "div", 8)(14, "label", 9);
      \u0275\u0275text(15, "Contrase\xF1a");
      \u0275\u0275elementEnd();
      \u0275\u0275elementStart(16, "input", 11);
      \u0275\u0275twoWayListener("ngModelChange", function Register_Template_input_ngModelChange_16_listener($event) {
        \u0275\u0275twoWayBindingSet(ctx.password, $event) || (ctx.password = $event);
        return $event;
      });
      \u0275\u0275elementEnd()();
      \u0275\u0275elementStart(17, "div", 8)(18, "label", 9);
      \u0275\u0275text(19, "Confirmar contrase\xF1a");
      \u0275\u0275elementEnd();
      \u0275\u0275elementStart(20, "input", 12);
      \u0275\u0275twoWayListener("ngModelChange", function Register_Template_input_ngModelChange_20_listener($event) {
        \u0275\u0275twoWayBindingSet(ctx.confirm, $event) || (ctx.confirm = $event);
        return $event;
      });
      \u0275\u0275elementEnd()();
      \u0275\u0275elementStart(21, "button", 13);
      \u0275\u0275conditionalCreate(22, Register_Conditional_22_Template, 1, 0, "span", 14);
      \u0275\u0275text(23, " Registrarse ");
      \u0275\u0275elementEnd()();
      \u0275\u0275element(24, "hr");
      \u0275\u0275elementStart(25, "p", 15);
      \u0275\u0275text(26, " \xBFYa tienes cuenta? ");
      \u0275\u0275elementStart(27, "a", 16);
      \u0275\u0275text(28, "Inicia sesi\xF3n");
      \u0275\u0275elementEnd()()()()();
    }
    if (rf & 2) {
      \u0275\u0275advance(6);
      \u0275\u0275conditional(ctx.error ? 6 : -1);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.success ? 7 : -1);
      \u0275\u0275advance(5);
      \u0275\u0275twoWayProperty("ngModel", ctx.username);
      \u0275\u0275advance(4);
      \u0275\u0275twoWayProperty("ngModel", ctx.password);
      \u0275\u0275advance(4);
      \u0275\u0275twoWayProperty("ngModel", ctx.confirm);
      \u0275\u0275advance();
      \u0275\u0275property("disabled", ctx.loading);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.loading ? 22 : -1);
    }
  }, dependencies: [FormsModule, \u0275NgNoValidate, DefaultValueAccessor, NgControlStatus, NgControlStatusGroup, RequiredValidator, NgModel, NgForm, RouterLink], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(Register, [{
    type: Component,
    args: [{ selector: "app-register", imports: [FormsModule, RouterLink], template: '<div class="min-vh-100 d-flex align-items-center justify-content-center">\n  <div class="card shadow" style="width: 380px">\n    <div class="card-body p-4">\n      <h4 class="card-title text-center mb-4">\n        <i class="bi bi-person-plus me-2 text-primary"></i>Crear cuenta\n      </h4>\n\n      @if (error) { <div class="alert alert-danger py-2">{{ error }}</div> }\n      @if (success) { <div class="alert alert-success py-2">{{ success }}</div> }\n\n      <form (ngSubmit)="submit()">\n        <div class="mb-3">\n          <label class="form-label">Usuario</label>\n          <input class="form-control" [(ngModel)]="username" name="username" required autofocus />\n        </div>\n        <div class="mb-3">\n          <label class="form-label">Contrase\xF1a</label>\n          <input class="form-control" type="password" [(ngModel)]="password" name="password" required />\n        </div>\n        <div class="mb-3">\n          <label class="form-label">Confirmar contrase\xF1a</label>\n          <input class="form-control" type="password" [(ngModel)]="confirm" name="confirm" required />\n        </div>\n        <button class="btn btn-primary w-100" type="submit" [disabled]="loading">\n          @if (loading) { <span class="spinner-border spinner-border-sm me-2"></span> }\n          Registrarse\n        </button>\n      </form>\n\n      <hr />\n      <p class="text-center mb-0 small">\n        \xBFYa tienes cuenta? <a routerLink="/login">Inicia sesi\xF3n</a>\n      </p>\n    </div>\n  </div>\n</div>\n' }]
  }], null, null);
})();
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(Register, { className: "Register", filePath: "src/app/pages/register/register.ts", lineNumber: 12 });
})();
export {
  Register
};
//# sourceMappingURL=chunk-ZZCXDVWQ.js.map
