import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel
} from "./chunk-TPOCFAFA.js";
import {
  CommonModule,
  Component,
  HttpClient,
  Injectable,
  inject,
  setClassMetadata,
  ɵsetClassDebugInfo,
  ɵɵadvance,
  ɵɵclassProp,
  ɵɵconditional,
  ɵɵconditionalCreate,
  ɵɵdefineComponent,
  ɵɵdefineInjectable,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtwoWayBindingSet,
  ɵɵtwoWayListener,
  ɵɵtwoWayProperty
} from "./chunk-UDUTJOOT.js";

// src/app/core/admin.ts
var API = "/api";
var AdminService = class _AdminService {
  http = inject(HttpClient);
  listUsers() {
    return this.http.get(`${API}/admin/users`);
  }
  deleteUser(id) {
    return this.http.delete(`${API}/admin/users/${id}`);
  }
  updateUser(id, body) {
    return this.http.patch(`${API}/admin/users/${id}`, body);
  }
  deleteDocument(id) {
    return this.http.delete(`${API}/admin/documents/${id}`);
  }
  static \u0275fac = function AdminService_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _AdminService)();
  };
  static \u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _AdminService, factory: _AdminService.\u0275fac, providedIn: "root" });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(AdminService, [{
    type: Injectable,
    args: [{ providedIn: "root" }]
  }], null, null);
})();

// src/app/pages/admin/admin.ts
var _forTrack0 = ($index, $item) => $item.id;
function Admin_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 3);
    \u0275\u0275text(1);
    \u0275\u0275elementStart(2, "button", 6);
    \u0275\u0275listener("click", function Admin_Conditional_4_Template_button_click_2_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.error = "");
    });
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.error, " ");
  }
}
function Admin_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275element(1, "span", 7);
    \u0275\u0275elementEnd();
  }
}
function Admin_Conditional_6_For_13_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "td");
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "td")(3, "input", 10);
    \u0275\u0275twoWayListener("ngModelChange", function Admin_Conditional_6_For_13_Conditional_1_Template_input_ngModelChange_3_listener($event) {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext(3);
      \u0275\u0275twoWayBindingSet(ctx_r1.editUsername, $event) || (ctx_r1.editUsername = $event);
      return \u0275\u0275resetView($event);
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "input", 11);
    \u0275\u0275twoWayListener("ngModelChange", function Admin_Conditional_6_For_13_Conditional_1_Template_input_ngModelChange_4_listener($event) {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext(3);
      \u0275\u0275twoWayBindingSet(ctx_r1.editPassword, $event) || (ctx_r1.editPassword = $event);
      return \u0275\u0275resetView($event);
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(5, "td")(6, "span", 12);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "td", 13)(9, "button", 14);
    \u0275\u0275listener("click", function Admin_Conditional_6_For_13_Conditional_1_Template_button_click_9_listener() {
      \u0275\u0275restoreView(_r3);
      const user_r4 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.saveEdit(user_r4.id));
    });
    \u0275\u0275element(10, "i", 15);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "button", 16);
    \u0275\u0275listener("click", function Admin_Conditional_6_For_13_Conditional_1_Template_button_click_11_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.editingId = null);
    });
    \u0275\u0275element(12, "i", 17);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const user_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(user_r4.id);
    \u0275\u0275advance(2);
    \u0275\u0275twoWayProperty("ngModel", ctx_r1.editUsername);
    \u0275\u0275advance();
    \u0275\u0275twoWayProperty("ngModel", ctx_r1.editPassword);
    \u0275\u0275advance(2);
    \u0275\u0275classProp("bg-danger", user_r4.is_admin)("bg-secondary", !user_r4.is_admin);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", user_r4.is_admin ? "Admin" : "Usuario", " ");
  }
}
function Admin_Conditional_6_For_13_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "td");
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "td");
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "td")(5, "span", 12);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "td", 13)(8, "button", 18);
    \u0275\u0275listener("click", function Admin_Conditional_6_For_13_Conditional_2_Template_button_click_8_listener() {
      \u0275\u0275restoreView(_r5);
      const user_r4 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.startEdit(user_r4));
    });
    \u0275\u0275element(9, "i", 19);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "button", 20);
    \u0275\u0275listener("click", function Admin_Conditional_6_For_13_Conditional_2_Template_button_click_10_listener() {
      \u0275\u0275restoreView(_r5);
      const user_r4 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.deleteUser(user_r4.id, user_r4.username));
    });
    \u0275\u0275element(11, "i", 21);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const user_r4 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(user_r4.id);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(user_r4.username);
    \u0275\u0275advance(2);
    \u0275\u0275classProp("bg-danger", user_r4.is_admin)("bg-secondary", !user_r4.is_admin);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", user_r4.is_admin ? "Admin" : "Usuario", " ");
  }
}
function Admin_Conditional_6_For_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr");
    \u0275\u0275conditionalCreate(1, Admin_Conditional_6_For_13_Conditional_1_Template, 13, 8)(2, Admin_Conditional_6_For_13_Conditional_2_Template, 12, 7);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const user_r4 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275conditional(ctx_r1.editingId === user_r4.id ? 1 : 2);
  }
}
function Admin_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5)(1, "table", 8)(2, "thead", 9)(3, "tr")(4, "th");
    \u0275\u0275text(5, "ID");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Usuario");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Rol");
    \u0275\u0275elementEnd();
    \u0275\u0275element(10, "th");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "tbody");
    \u0275\u0275repeaterCreate(12, Admin_Conditional_6_For_13_Template, 3, 1, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(12);
    \u0275\u0275repeater(ctx_r1.users);
  }
}
var Admin = class _Admin {
  svc = inject(AdminService);
  users = [];
  loading = false;
  error = "";
  editingId = null;
  editUsername = "";
  editPassword = "";
  ngOnInit() {
    this.load();
  }
  load() {
    this.loading = true;
    this.svc.listUsers().subscribe({
      next: (u) => {
        this.users = u;
        this.loading = false;
      },
      error: () => {
        this.error = "Error al cargar usuarios.";
        this.loading = false;
      }
    });
  }
  startEdit(user) {
    this.editingId = user.id;
    this.editUsername = user.username;
    this.editPassword = "";
  }
  saveEdit(id) {
    const body = {};
    if (this.editUsername)
      body.username = this.editUsername;
    if (this.editPassword)
      body.password = this.editPassword;
    this.svc.updateUser(id, body).subscribe({
      next: () => {
        this.editingId = null;
        this.load();
      },
      error: () => {
        this.error = "Error al actualizar usuario.";
      }
    });
  }
  deleteUser(id, username) {
    if (!confirm(`\xBFEliminar al usuario "${username}" y todos sus documentos?`))
      return;
    this.svc.deleteUser(id).subscribe(() => this.load());
  }
  static \u0275fac = function Admin_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _Admin)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _Admin, selectors: [["app-admin"]], decls: 7, vars: 2, consts: [[1, "container", "py-4"], [1, "mb-4"], [1, "bi", "bi-people", "me-2"], [1, "alert", "alert-danger", "py-2", "alert-dismissible"], [1, "text-center", "py-5"], [1, "table-responsive"], [1, "btn-close", 3, "click"], [1, "spinner-border", "text-primary"], [1, "table", "table-hover", "align-middle"], [1, "table-light"], ["placeholder", "Nuevo usuario", 1, "form-control", "form-control-sm", "d-inline-block", "me-1", 2, "width", "140px", 3, "ngModelChange", "ngModel"], ["type", "password", "placeholder", "Nueva contrase\xF1a", 1, "form-control", "form-control-sm", "d-inline-block", 2, "width", "140px", 3, "ngModelChange", "ngModel"], [1, "badge"], [1, "text-end"], [1, "btn", "btn-success", "btn-sm", "me-1", 3, "click"], [1, "bi", "bi-check-lg"], [1, "btn", "btn-secondary", "btn-sm", 3, "click"], [1, "bi", "bi-x-lg"], ["title", "Editar", 1, "btn", "btn-outline-secondary", "btn-sm", "me-1", 3, "click"], [1, "bi", "bi-pencil"], ["title", "Eliminar", 1, "btn", "btn-outline-danger", "btn-sm", 3, "click"], [1, "bi", "bi-trash"]], template: function Admin_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275elementStart(0, "div", 0)(1, "h5", 1);
      \u0275\u0275element(2, "i", 2);
      \u0275\u0275text(3, "Panel de administraci\xF3n");
      \u0275\u0275elementEnd();
      \u0275\u0275conditionalCreate(4, Admin_Conditional_4_Template, 3, 1, "div", 3);
      \u0275\u0275conditionalCreate(5, Admin_Conditional_5_Template, 2, 0, "div", 4)(6, Admin_Conditional_6_Template, 14, 0, "div", 5);
      \u0275\u0275elementEnd();
    }
    if (rf & 2) {
      \u0275\u0275advance(4);
      \u0275\u0275conditional(ctx.error ? 4 : -1);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.loading ? 5 : 6);
    }
  }, dependencies: [CommonModule, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(Admin, [{
    type: Component,
    args: [{ selector: "app-admin", imports: [CommonModule, FormsModule], template: `<div class="container py-4">
  <h5 class="mb-4"><i class="bi bi-people me-2"></i>Panel de administraci\xF3n</h5>

  @if (error) {
    <div class="alert alert-danger py-2 alert-dismissible">
      {{ error }}
      <button class="btn-close" (click)="error=''"></button>
    </div>
  }

  @if (loading) {
    <div class="text-center py-5"><span class="spinner-border text-primary"></span></div>
  } @else {
    <div class="table-responsive">
      <table class="table table-hover align-middle">
        <thead class="table-light">
          <tr>
            <th>ID</th>
            <th>Usuario</th>
            <th>Rol</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          @for (user of users; track user.id) {
            <tr>
              @if (editingId === user.id) {
                <td>{{ user.id }}</td>
                <td>
                  <input class="form-control form-control-sm d-inline-block me-1" style="width:140px"
                    [(ngModel)]="editUsername" placeholder="Nuevo usuario" />
                  <input class="form-control form-control-sm d-inline-block" style="width:140px"
                    type="password" [(ngModel)]="editPassword" placeholder="Nueva contrase\xF1a" />
                </td>
                <td>
                  <span class="badge" [class.bg-danger]="user.is_admin" [class.bg-secondary]="!user.is_admin">
                    {{ user.is_admin ? 'Admin' : 'Usuario' }}
                  </span>
                </td>
                <td class="text-end">
                  <button class="btn btn-success btn-sm me-1" (click)="saveEdit(user.id)">
                    <i class="bi bi-check-lg"></i>
                  </button>
                  <button class="btn btn-secondary btn-sm" (click)="editingId=null">
                    <i class="bi bi-x-lg"></i>
                  </button>
                </td>
              } @else {
                <td>{{ user.id }}</td>
                <td>{{ user.username }}</td>
                <td>
                  <span class="badge" [class.bg-danger]="user.is_admin" [class.bg-secondary]="!user.is_admin">
                    {{ user.is_admin ? 'Admin' : 'Usuario' }}
                  </span>
                </td>
                <td class="text-end">
                  <button class="btn btn-outline-secondary btn-sm me-1" (click)="startEdit(user)" title="Editar">
                    <i class="bi bi-pencil"></i>
                  </button>
                  <button class="btn btn-outline-danger btn-sm" (click)="deleteUser(user.id, user.username)" title="Eliminar">
                    <i class="bi bi-trash"></i>
                  </button>
                </td>
              }
            </tr>
          }
        </tbody>
      </table>
    </div>
  }
</div>
` }]
  }], null, null);
})();
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(Admin, { className: "Admin", filePath: "src/app/pages/admin/admin.ts", lineNumber: 12 });
})();
export {
  Admin
};
//# sourceMappingURL=chunk-PQUNRX26.js.map
