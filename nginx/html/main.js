import {
  AuthService,
  Router,
  RouterLink,
  RouterLinkActive,
  RouterOutlet,
  authInterceptor,
  bootstrapApplication,
  provideRouter
} from "./chunk-BLNTAYHO.js";
import {
  Component,
  inject,
  provideBrowserGlobalErrorListeners,
  provideHttpClient,
  setClassMetadata,
  withInterceptors,
  ɵsetClassDebugInfo,
  ɵɵadvance,
  ɵɵconditional,
  ɵɵconditionalCreate,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtext
} from "./chunk-UDUTJOOT.js";

// src/app/core/auth-guard.ts
var authGuard = () => {
  const auth = inject(AuthService);
  if (auth.isLoggedIn())
    return true;
  inject(Router).navigate(["/login"]);
  return false;
};

// src/app/core/admin-guard.ts
var adminGuard = () => {
  const auth = inject(AuthService);
  if (auth.isAdmin())
    return true;
  inject(Router).navigate(["/dashboard"]);
  return false;
};

// src/app/app.routes.ts
var routes = [
  { path: "", redirectTo: "dashboard", pathMatch: "full" },
  {
    path: "login",
    loadComponent: () => import("./chunk-KQWPEVYX.js").then((m) => m.Login)
  },
  {
    path: "register",
    loadComponent: () => import("./chunk-ZZCXDVWQ.js").then((m) => m.Register)
  },
  {
    path: "dashboard",
    loadComponent: () => import("./chunk-3N6XN6C7.js").then((m) => m.Dashboard),
    canActivate: [authGuard]
  },
  {
    path: "admin",
    loadComponent: () => import("./chunk-PQUNRX26.js").then((m) => m.Admin),
    canActivate: [authGuard, adminGuard]
  },
  { path: "**", redirectTo: "dashboard" }
];

// src/app/app.config.ts
var appConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};

// src/app/shared/navbar/navbar.ts
function Navbar_Conditional_0_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "a", 6);
    \u0275\u0275element(1, "i", 9);
    \u0275\u0275text(2, "Admin ");
    \u0275\u0275elementEnd();
  }
}
function Navbar_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "nav", 0)(1, "span", 1);
    \u0275\u0275element(2, "i", 2);
    \u0275\u0275text(3, "ScienClassifier ");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 3)(5, "a", 4);
    \u0275\u0275element(6, "i", 5);
    \u0275\u0275text(7, "Mis documentos ");
    \u0275\u0275elementEnd();
    \u0275\u0275conditionalCreate(8, Navbar_Conditional_0_Conditional_8_Template, 3, 0, "a", 6);
    \u0275\u0275elementStart(9, "button", 7);
    \u0275\u0275listener("click", function Navbar_Conditional_0_Template_button_click_9_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.auth.logout());
    });
    \u0275\u0275element(10, "i", 8);
    \u0275\u0275text(11, "Salir ");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(8);
    \u0275\u0275conditional(ctx_r1.auth.isAdmin() ? 8 : -1);
  }
}
var Navbar = class _Navbar {
  auth = inject(AuthService);
  static \u0275fac = function Navbar_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _Navbar)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _Navbar, selectors: [["app-navbar"]], decls: 1, vars: 1, consts: [[1, "navbar", "navbar-expand-lg", "navbar-dark", "bg-dark", "px-3"], [1, "navbar-brand", "fw-bold"], [1, "bi", "bi-journal-richtext", "me-2"], [1, "navbar-nav", "ms-auto", "d-flex", "flex-row", "gap-3", "align-items-center"], ["routerLink", "/dashboard", "routerLinkActive", "active", 1, "nav-link"], [1, "bi", "bi-files", "me-1"], ["routerLink", "/admin", "routerLinkActive", "active", 1, "nav-link"], [1, "btn", "btn-outline-light", "btn-sm", 3, "click"], [1, "bi", "bi-box-arrow-right", "me-1"], [1, "bi", "bi-people", "me-1"]], template: function Navbar_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275conditionalCreate(0, Navbar_Conditional_0_Template, 12, 1, "nav", 0);
    }
    if (rf & 2) {
      \u0275\u0275conditional(ctx.auth.isLoggedIn() ? 0 : -1);
    }
  }, dependencies: [RouterLink, RouterLinkActive], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(Navbar, [{
    type: Component,
    args: [{ selector: "app-navbar", imports: [RouterLink, RouterLinkActive], template: `
    @if (auth.isLoggedIn()) {
      <nav class="navbar navbar-expand-lg navbar-dark bg-dark px-3">
        <span class="navbar-brand fw-bold">
          <i class="bi bi-journal-richtext me-2"></i>ScienClassifier
        </span>
        <div class="navbar-nav ms-auto d-flex flex-row gap-3 align-items-center">
          <a class="nav-link" routerLink="/dashboard" routerLinkActive="active">
            <i class="bi bi-files me-1"></i>Mis documentos
          </a>
          @if (auth.isAdmin()) {
            <a class="nav-link" routerLink="/admin" routerLinkActive="active">
              <i class="bi bi-people me-1"></i>Admin
            </a>
          }
          <button class="btn btn-outline-light btn-sm" (click)="auth.logout()">
            <i class="bi bi-box-arrow-right me-1"></i>Salir
          </button>
        </div>
      </nav>
    }
  ` }]
  }], null, null);
})();
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(Navbar, { className: "Navbar", filePath: "src/app/shared/navbar/navbar.ts", lineNumber: 32 });
})();

// src/app/app.ts
var App = class _App {
  static \u0275fac = function App_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _App)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _App, selectors: [["app-root"]], decls: 2, vars: 0, template: function App_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275element(0, "app-navbar")(1, "router-outlet");
    }
  }, dependencies: [RouterOutlet, Navbar], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(App, [{
    type: Component,
    args: [{
      selector: "app-root",
      imports: [RouterOutlet, Navbar],
      template: `
    <app-navbar />
    <router-outlet />
  `
    }]
  }], null, null);
})();
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(App, { className: "App", filePath: "src/app/app.ts", lineNumber: 13 });
})();

// src/main.ts
bootstrapApplication(App, appConfig).catch((err) => console.error(err));
//# sourceMappingURL=main.js.map
