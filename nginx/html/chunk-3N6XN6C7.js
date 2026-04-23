import {
  FormsModule
} from "./chunk-TPOCFAFA.js";
import {
  CommonModule,
  Component,
  DatePipe,
  HttpClient,
  Injectable,
  inject,
  setClassMetadata,
  ɵsetClassDebugInfo,
  ɵɵadvance,
  ɵɵclassMap,
  ɵɵclassProp,
  ɵɵconditional,
  ɵɵconditionalCreate,
  ɵɵdefineComponent,
  ɵɵdefineInjectable,
  ɵɵdomElement,
  ɵɵdomElementEnd,
  ɵɵdomElementStart,
  ɵɵdomListener,
  ɵɵdomProperty,
  ɵɵgetCurrentView,
  ɵɵnextContext,
  ɵɵpipe,
  ɵɵpipeBind2,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIndex,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-UDUTJOOT.js";

// src/app/core/document.ts
var API = "/api";
var DocumentService = class _DocumentService {
  http = inject(HttpClient);
  list() {
    return this.http.get(`${API}/documents`);
  }
  upload(file) {
    const form = new FormData();
    form.append("file", file);
    return this.http.post(`${API}/documents`, form);
  }
  download(id) {
    return this.http.get(`${API}/documents/${id}/download`, {
      responseType: "blob",
      observe: "response"
    });
  }
  delete(id) {
    return this.http.delete(`${API}/documents/${id}`);
  }
  deleteBatch(ids) {
    return this.http.post(`${API}/documents/delete-batch`, { document_ids: ids });
  }
  apa7(ids) {
    return this.http.post(`${API}/documents/apa7`, { document_ids: ids });
  }
  static \u0275fac = function DocumentService_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _DocumentService)();
  };
  static \u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _DocumentService, factory: _DocumentService.\u0275fac, providedIn: "root" });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(DocumentService, [{
    type: Injectable,
    args: [{ providedIn: "root" }]
  }], null, null);
})();

// src/app/pages/dashboard/dashboard.ts
var _forTrack0 = ($index, $item) => $item.id;
var _forTrack1 = ($index, $item) => $item.category;
function Dashboard_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "button", 14);
    \u0275\u0275domListener("click", function Dashboard_Conditional_6_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.deleteSelected());
    });
    \u0275\u0275domElement(1, "i", 15);
    \u0275\u0275text(2);
    \u0275\u0275domElementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Eliminar (", ctx_r1.selected.size, ") ");
  }
}
function Dashboard_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "button", 16);
    \u0275\u0275domListener("click", function Dashboard_Conditional_7_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.generateApa7());
    });
    \u0275\u0275domElement(1, "i", 17);
    \u0275\u0275text(2);
    \u0275\u0275domElementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1(" ", ctx_r1.selected.size ? "APA7 (" + ctx_r1.selected.size + ")" : "APA7 todos", " ");
  }
}
function Dashboard_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElement(0, "span", 18)(1, "i", 19);
    \u0275\u0275text(2);
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275classMap(ctx_r1.uploadPhase.icon);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("", ctx_r1.uploadPhase.label, " ");
  }
}
function Dashboard_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElement(0, "i", 20);
    \u0275\u0275text(1, "Subir PDF ");
  }
}
function Dashboard_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "div", 9);
    \u0275\u0275domElement(1, "i", 21);
    \u0275\u0275domElementStart(2, "span");
    \u0275\u0275text(3);
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(4, "button", 22);
    \u0275\u0275domListener("click", function Dashboard_Conditional_12_Template_button_click_4_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.error = "");
    });
    \u0275\u0275domElementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r1.error);
  }
}
function Dashboard_Conditional_13_For_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "p", 30);
    \u0275\u0275text(1);
    \u0275\u0275domElementEnd();
  }
  if (rf & 2) {
    const c_r6 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(c_r6);
  }
}
function Dashboard_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "div", 10)(1, "div", 23)(2, "div", 24)(3, "div", 25)(4, "h5", 26);
    \u0275\u0275domElement(5, "i", 27);
    \u0275\u0275text(6, "Citas APA 7");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(7, "button", 28);
    \u0275\u0275domListener("click", function Dashboard_Conditional_13_Template_button_click_7_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.showCitations = false);
    });
    \u0275\u0275domElementEnd()();
    \u0275\u0275domElementStart(8, "div", 29);
    \u0275\u0275repeaterCreate(9, Dashboard_Conditional_13_For_10_Template, 2, 1, "p", 30, \u0275\u0275repeaterTrackByIndex);
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(11, "div", 31)(12, "button", 16);
    \u0275\u0275domListener("click", function Dashboard_Conditional_13_Template_button_click_12_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.copyCitations());
    });
    \u0275\u0275domElement(13, "i", 32);
    \u0275\u0275text(14, "Copiar todo ");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(15, "button", 33);
    \u0275\u0275domListener("click", function Dashboard_Conditional_13_Template_button_click_15_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.showCitations = false);
    });
    \u0275\u0275text(16, "Cerrar");
    \u0275\u0275domElementEnd()()()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(9);
    \u0275\u0275repeater(ctx_r1.citations);
  }
}
function Dashboard_Conditional_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "div", 11);
    \u0275\u0275domElement(1, "span", 34);
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "div", 12);
    \u0275\u0275domElement(1, "i", 35);
    \u0275\u0275text(2, " No has subido ning\xFAn documento todav\xEDa. ");
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_16_For_15_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "small", 42);
    \u0275\u0275text(1);
    \u0275\u0275domElementEnd();
  }
  if (rf & 2) {
    const doc_r9 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(doc_r9.authors);
  }
}
function Dashboard_Conditional_16_For_15_Case_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "span", 43);
    \u0275\u0275domElement(1, "span", 52);
    \u0275\u0275text(2, " En cola... ");
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_16_For_15_Case_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "span", 44);
    \u0275\u0275domElement(1, "span", 52);
    \u0275\u0275text(2, " Clasificando... ");
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_16_For_15_Case_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "span", 45);
    \u0275\u0275domElement(1, "i", 53);
    \u0275\u0275text(2, "Error al clasificar ");
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_16_For_15_Case_11_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "span", 54);
    \u0275\u0275text(1, "Sin categor\xEDas");
    \u0275\u0275domElementEnd();
  }
}
function Dashboard_Conditional_16_For_15_Case_11_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275domElementStart(0, "span", 56);
    \u0275\u0275text(1);
    \u0275\u0275domElementEnd();
  }
  if (rf & 2) {
    const cat_r10 = ctx.$implicit;
    \u0275\u0275classProp("bg-primary", cat_r10.score >= 80)("bg-info", cat_r10.score >= 50 && cat_r10.score < 80)("bg-secondary", cat_r10.score < 50);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2(" ", cat_r10.category, " ", cat_r10.score, "% ");
  }
}
function Dashboard_Conditional_16_For_15_Case_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275conditionalCreate(0, Dashboard_Conditional_16_For_15_Case_11_Conditional_0_Template, 2, 0, "span", 54);
    \u0275\u0275repeaterCreate(1, Dashboard_Conditional_16_For_15_Case_11_For_2_Template, 2, 8, "span", 55, _forTrack1);
  }
  if (rf & 2) {
    const doc_r9 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275conditional(doc_r9.categories.length === 0 ? 0 : -1);
    \u0275\u0275advance();
    \u0275\u0275repeater(doc_r9.categories);
  }
}
function Dashboard_Conditional_16_For_15_Template(rf, ctx) {
  if (rf & 1) {
    const _r8 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "tr")(1, "td")(2, "input", 39);
    \u0275\u0275domListener("change", function Dashboard_Conditional_16_For_15_Template_input_change_2_listener() {
      const doc_r9 = \u0275\u0275restoreView(_r8).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.toggle(doc_r9.id));
    });
    \u0275\u0275domElementEnd()();
    \u0275\u0275domElementStart(3, "td")(4, "div", 41);
    \u0275\u0275text(5);
    \u0275\u0275domElementEnd();
    \u0275\u0275conditionalCreate(6, Dashboard_Conditional_16_For_15_Conditional_6_Template, 2, 1, "small", 42);
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(7, "td");
    \u0275\u0275conditionalCreate(8, Dashboard_Conditional_16_For_15_Case_8_Template, 3, 0, "span", 43)(9, Dashboard_Conditional_16_For_15_Case_9_Template, 3, 0, "span", 44)(10, Dashboard_Conditional_16_For_15_Case_10_Template, 3, 0, "span", 45)(11, Dashboard_Conditional_16_For_15_Case_11_Template, 3, 1);
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(12, "td", 46);
    \u0275\u0275text(13);
    \u0275\u0275pipe(14, "date");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(15, "td", 47)(16, "button", 48);
    \u0275\u0275domListener("click", function Dashboard_Conditional_16_For_15_Template_button_click_16_listener() {
      const doc_r9 = \u0275\u0275restoreView(_r8).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.download(doc_r9));
    });
    \u0275\u0275domElement(17, "i", 49);
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(18, "button", 50);
    \u0275\u0275domListener("click", function Dashboard_Conditional_16_For_15_Template_button_click_18_listener() {
      const doc_r9 = \u0275\u0275restoreView(_r8).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.deleteOne(doc_r9.id));
    });
    \u0275\u0275domElement(19, "i", 51);
    \u0275\u0275domElementEnd()()();
  }
  if (rf & 2) {
    let tmp_15_0;
    const doc_r9 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275classProp("table-active", ctx_r1.selected.has(doc_r9.id));
    \u0275\u0275advance(2);
    \u0275\u0275domProperty("checked", ctx_r1.selected.has(doc_r9.id));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(doc_r9.title || doc_r9.filename);
    \u0275\u0275advance();
    \u0275\u0275conditional(doc_r9.authors ? 6 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275conditional((tmp_15_0 = doc_r9.status) === "pending" ? 8 : tmp_15_0 === "processing" ? 9 : tmp_15_0 === "error" ? 10 : 11);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1(" ", \u0275\u0275pipeBind2(14, 8, doc_r9.uploaded_at, "dd/MM/yyyy HH:mm"), " ");
    \u0275\u0275advance(3);
    \u0275\u0275domProperty("disabled", doc_r9.status !== "done" && doc_r9.categories.length === 0);
  }
}
function Dashboard_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    const _r7 = \u0275\u0275getCurrentView();
    \u0275\u0275domElementStart(0, "div", 13)(1, "table", 36)(2, "thead", 37)(3, "tr")(4, "th", 38)(5, "input", 39);
    \u0275\u0275domListener("change", function Dashboard_Conditional_16_Template_input_change_5_listener() {
      \u0275\u0275restoreView(_r7);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.toggleAll());
    });
    \u0275\u0275domElementEnd()();
    \u0275\u0275domElementStart(6, "th");
    \u0275\u0275text(7, "Archivo");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(8, "th");
    \u0275\u0275text(9, "Categor\xEDas");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElementStart(10, "th");
    \u0275\u0275text(11, "Subido");
    \u0275\u0275domElementEnd();
    \u0275\u0275domElement(12, "th");
    \u0275\u0275domElementEnd()();
    \u0275\u0275domElementStart(13, "tbody");
    \u0275\u0275repeaterCreate(14, Dashboard_Conditional_16_For_15_Template, 20, 11, "tr", 40, _forTrack0);
    \u0275\u0275domElementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(5);
    \u0275\u0275domProperty("checked", ctx_r1.selected.size === ctx_r1.docs.length && ctx_r1.docs.length > 0);
    \u0275\u0275advance(9);
    \u0275\u0275repeater(ctx_r1.docs);
  }
}
var UPLOAD_PHASES = [
  { label: "Verificando formato...", icon: "bi-file-earmark-check", duration: 1500 },
  { label: "Validando contenido e idioma...", icon: "bi-translate", duration: 2500 },
  { label: "Subiendo a la nube...", icon: "bi-cloud-upload", duration: 99999 }
];
var Dashboard = class _Dashboard {
  svc = inject(DocumentService);
  pollTimer = null;
  phaseTimer = null;
  docs = [];
  selected = /* @__PURE__ */ new Set();
  loading = false;
  error = "";
  citations = [];
  showCitations = false;
  uploading = false;
  uploadPhaseIndex = 0;
  get uploadPhase() {
    return UPLOAD_PHASES[this.uploadPhaseIndex];
  }
  ngOnInit() {
    this.load();
  }
  ngOnDestroy() {
    this.stopPolling();
    if (this.phaseTimer)
      clearTimeout(this.phaseTimer);
  }
  load() {
    this.loading = true;
    this.svc.list().subscribe({
      next: (docs) => {
        this.docs = docs;
        this.loading = false;
        this.managePoll();
      },
      error: () => {
        this.error = "Error al cargar documentos.";
        this.loading = false;
      }
    });
  }
  hasPending() {
    return this.docs.some((d) => d.status === "pending" || d.status === "processing");
  }
  managePoll() {
    if (this.hasPending()) {
      this.startPolling();
    } else {
      this.stopPolling();
    }
  }
  startPolling() {
    if (this.pollTimer)
      return;
    this.pollTimer = setInterval(() => {
      this.svc.list().subscribe((docs) => {
        this.docs = docs;
        if (!this.hasPending())
          this.stopPolling();
      });
    }, 3e3);
  }
  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }
  advancePhase(index) {
    if (index >= UPLOAD_PHASES.length - 1)
      return;
    this.phaseTimer = setTimeout(() => {
      this.uploadPhaseIndex = index + 1;
      this.advancePhase(index + 1);
    }, UPLOAD_PHASES[index].duration);
  }
  toggle(id) {
    this.selected.has(id) ? this.selected.delete(id) : this.selected.add(id);
  }
  toggleAll() {
    if (this.selected.size === this.docs.length)
      this.selected.clear();
    else
      this.docs.forEach((d) => this.selected.add(d.id));
  }
  onFileChange(event) {
    const input = event.target;
    const file = input.files?.[0];
    if (!file)
      return;
    if (file.type !== "application/pdf") {
      this.error = "Solo se aceptan archivos PDF (.pdf).";
      input.value = "";
      return;
    }
    this.uploading = true;
    this.uploadPhaseIndex = 0;
    this.error = "";
    this.advancePhase(0);
    this.svc.upload(file).subscribe({
      next: () => {
        this.finishUpload(input);
        this.load();
      },
      error: (e) => {
        this.error = e.error?.detail ?? "Error al subir el archivo.";
        this.finishUpload(input);
      }
    });
  }
  finishUpload(input) {
    if (this.phaseTimer) {
      clearTimeout(this.phaseTimer);
      this.phaseTimer = null;
    }
    this.uploading = false;
    this.uploadPhaseIndex = 0;
    input.value = "";
  }
  download(doc) {
    this.svc.download(doc.id).subscribe((res) => {
      const url = URL.createObjectURL(res.body);
      const a = document.createElement("a");
      a.href = url;
      a.download = doc.filename;
      a.click();
      URL.revokeObjectURL(url);
    });
  }
  deleteOne(id) {
    if (!confirm("\xBFEliminar este documento?"))
      return;
    this.svc.delete(id).subscribe(() => {
      this.selected.delete(id);
      this.load();
    });
  }
  deleteSelected() {
    if (!this.selected.size)
      return;
    if (!confirm(`\xBFEliminar ${this.selected.size} documento(s)?`))
      return;
    this.svc.deleteBatch([...this.selected]).subscribe(() => {
      this.selected.clear();
      this.load();
    });
  }
  generateApa7() {
    const ids = this.selected.size ? [...this.selected] : this.docs.map((d) => d.id);
    this.svc.apa7(ids).subscribe((res) => {
      this.citations = res.citations;
      this.showCitations = true;
    });
  }
  copyCitations() {
    navigator.clipboard.writeText(this.citations.join("\n\n"));
  }
  static \u0275fac = function Dashboard_Factory(__ngFactoryType__) {
    return new (__ngFactoryType__ || _Dashboard)();
  };
  static \u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _Dashboard, selectors: [["app-dashboard"]], decls: 17, vars: 9, consts: [[1, "container", "py-4"], [1, "d-flex", "align-items-center", "justify-content-between", "mb-3"], [1, "mb-0"], [1, "bi", "bi-files", "me-2"], [1, "d-flex", "gap-2", "align-items-center"], [1, "btn", "btn-outline-danger", "btn-sm"], [1, "btn", "btn-outline-secondary", "btn-sm"], [1, "btn", "btn-primary", "btn-sm", "mb-0"], ["type", "file", "accept", ".pdf", 1, "d-none", 3, "change", "disabled"], [1, "alert", "alert-danger", "alert-dismissible", "py-2", "d-flex", "align-items-center", "gap-2"], ["tabindex", "-1", 1, "modal", "d-block", 2, "background", "rgba(0,0,0,.4)"], [1, "text-center", "py-5"], [1, "text-center", "text-muted", "py-5"], [1, "table-responsive"], [1, "btn", "btn-outline-danger", "btn-sm", 3, "click"], [1, "bi", "bi-trash", "me-1"], [1, "btn", "btn-outline-secondary", "btn-sm", 3, "click"], [1, "bi", "bi-quote", "me-1"], [1, "spinner-border", "spinner-border-sm", "me-1"], [1, "bi", "me-1"], [1, "bi", "bi-upload", "me-1"], [1, "bi", "bi-exclamation-triangle-fill"], ["type", "button", 1, "btn-close", "ms-auto", 3, "click"], [1, "modal-dialog", "modal-lg"], [1, "modal-content"], [1, "modal-header"], [1, "modal-title"], [1, "bi", "bi-quote", "me-2"], [1, "btn-close", 3, "click"], [1, "modal-body"], [1, "border-bottom", "pb-2"], [1, "modal-footer"], [1, "bi", "bi-clipboard", "me-1"], [1, "btn", "btn-secondary", "btn-sm", 3, "click"], [1, "spinner-border", "text-primary"], [1, "bi", "bi-inbox", "fs-1", "d-block", "mb-2"], [1, "table", "table-hover", "align-middle"], [1, "table-light"], [2, "width", "36px"], ["type", "checkbox", 1, "form-check-input", 3, "change", "checked"], [3, "table-active"], [1, "fw-semibold"], [1, "text-muted"], [1, "badge", "bg-warning", "text-dark"], [1, "badge", "bg-info", "text-dark"], [1, "badge", "bg-danger"], [1, "text-muted", "small", "text-nowrap"], [1, "text-end", "text-nowrap"], ["title", "Descargar", 1, "btn", "btn-outline-primary", "btn-sm", "me-1", 3, "click", "disabled"], [1, "bi", "bi-download"], ["title", "Eliminar", 1, "btn", "btn-outline-danger", "btn-sm", 3, "click"], [1, "bi", "bi-trash"], [1, "spinner-border", "spinner-border-sm", "me-1", 2, "width", ".6rem", "height", ".6rem"], [1, "bi", "bi-exclamation-circle", "me-1"], [1, "text-muted", "small"], [1, "badge", "me-1", "mb-1", "category-badge", 3, "bg-primary", "bg-info", "bg-secondary"], [1, "badge", "me-1", "mb-1", "category-badge"]], template: function Dashboard_Template(rf, ctx) {
    if (rf & 1) {
      \u0275\u0275domElementStart(0, "div", 0)(1, "div", 1)(2, "h5", 2);
      \u0275\u0275domElement(3, "i", 3);
      \u0275\u0275text(4, "Mis documentos");
      \u0275\u0275domElementEnd();
      \u0275\u0275domElementStart(5, "div", 4);
      \u0275\u0275conditionalCreate(6, Dashboard_Conditional_6_Template, 3, 1, "button", 5);
      \u0275\u0275conditionalCreate(7, Dashboard_Conditional_7_Template, 3, 1, "button", 6);
      \u0275\u0275domElementStart(8, "label", 7);
      \u0275\u0275conditionalCreate(9, Dashboard_Conditional_9_Template, 3, 3)(10, Dashboard_Conditional_10_Template, 2, 0);
      \u0275\u0275domElementStart(11, "input", 8);
      \u0275\u0275domListener("change", function Dashboard_Template_input_change_11_listener($event) {
        return ctx.onFileChange($event);
      });
      \u0275\u0275domElementEnd()()()();
      \u0275\u0275conditionalCreate(12, Dashboard_Conditional_12_Template, 5, 1, "div", 9);
      \u0275\u0275conditionalCreate(13, Dashboard_Conditional_13_Template, 17, 0, "div", 10);
      \u0275\u0275conditionalCreate(14, Dashboard_Conditional_14_Template, 2, 0, "div", 11)(15, Dashboard_Conditional_15_Template, 3, 0, "div", 12)(16, Dashboard_Conditional_16_Template, 16, 1, "div", 13);
      \u0275\u0275domElementEnd();
    }
    if (rf & 2) {
      \u0275\u0275advance(6);
      \u0275\u0275conditional(ctx.selected.size > 0 ? 6 : -1);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.docs.length > 0 ? 7 : -1);
      \u0275\u0275advance();
      \u0275\u0275classProp("disabled", ctx.uploading);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.uploading ? 9 : 10);
      \u0275\u0275advance(2);
      \u0275\u0275domProperty("disabled", ctx.uploading);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.error ? 12 : -1);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.showCitations ? 13 : -1);
      \u0275\u0275advance();
      \u0275\u0275conditional(ctx.loading ? 14 : ctx.docs.length === 0 ? 15 : 16);
    }
  }, dependencies: [CommonModule, FormsModule, DatePipe], encapsulation: 2 });
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && setClassMetadata(Dashboard, [{
    type: Component,
    args: [{ selector: "app-dashboard", imports: [CommonModule, FormsModule], template: `<div class="container py-4">

  <!-- Cabecera -->
  <div class="d-flex align-items-center justify-content-between mb-3">
    <h5 class="mb-0"><i class="bi bi-files me-2"></i>Mis documentos</h5>
    <div class="d-flex gap-2 align-items-center">
      @if (selected.size > 0) {
        <button class="btn btn-outline-danger btn-sm" (click)="deleteSelected()">
          <i class="bi bi-trash me-1"></i>Eliminar ({{ selected.size }})
        </button>
      }
      @if (docs.length > 0) {
        <button class="btn btn-outline-secondary btn-sm" (click)="generateApa7()">
          <i class="bi bi-quote me-1"></i>
          {{ selected.size ? 'APA7 (' + selected.size + ')' : 'APA7 todos' }}
        </button>
      }
      <label class="btn btn-primary btn-sm mb-0" [class.disabled]="uploading">
        @if (uploading) {
          <span class="spinner-border spinner-border-sm me-1"></span>
          <i class="bi me-1" [class]="uploadPhase.icon"></i>{{ uploadPhase.label }}
        } @else {
          <i class="bi bi-upload me-1"></i>Subir PDF
        }
        <input type="file" accept=".pdf" class="d-none"
          (change)="onFileChange($event)" [disabled]="uploading" />
      </label>
    </div>
  </div>

  <!-- Error -->
  @if (error) {
    <div class="alert alert-danger alert-dismissible py-2 d-flex align-items-center gap-2">
      <i class="bi bi-exclamation-triangle-fill"></i>
      <span>{{ error }}</span>
      <button type="button" class="btn-close ms-auto" (click)="error=''"></button>
    </div>
  }

  <!-- Modal APA7 -->
  @if (showCitations) {
    <div class="modal d-block" tabindex="-1" style="background:rgba(0,0,0,.4)">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title"><i class="bi bi-quote me-2"></i>Citas APA 7</h5>
            <button class="btn-close" (click)="showCitations=false"></button>
          </div>
          <div class="modal-body">
            @for (c of citations; track $index) {
              <p class="border-bottom pb-2">{{ c }}</p>
            }
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary btn-sm" (click)="copyCitations()">
              <i class="bi bi-clipboard me-1"></i>Copiar todo
            </button>
            <button class="btn btn-secondary btn-sm" (click)="showCitations=false">Cerrar</button>
          </div>
        </div>
      </div>
    </div>
  }

  <!-- Tabla -->
  @if (loading) {
    <div class="text-center py-5"><span class="spinner-border text-primary"></span></div>
  } @else if (docs.length === 0) {
    <div class="text-center text-muted py-5">
      <i class="bi bi-inbox fs-1 d-block mb-2"></i>
      No has subido ning\xFAn documento todav\xEDa.
    </div>
  } @else {
    <div class="table-responsive">
      <table class="table table-hover align-middle">
        <thead class="table-light">
          <tr>
            <th style="width:36px">
              <input type="checkbox" class="form-check-input"
                [checked]="selected.size === docs.length && docs.length > 0"
                (change)="toggleAll()" />
            </th>
            <th>Archivo</th>
            <th>Categor\xEDas</th>
            <th>Subido</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          @for (doc of docs; track doc.id) {
            <tr [class.table-active]="selected.has(doc.id)">
              <td>
                <input type="checkbox" class="form-check-input"
                  [checked]="selected.has(doc.id)"
                  (change)="toggle(doc.id)" />
              </td>
              <td>
                <div class="fw-semibold">{{ doc.title || doc.filename }}</div>
                @if (doc.authors) {
                  <small class="text-muted">{{ doc.authors }}</small>
                }
              </td>
              <td>
                @switch (doc.status) {
                  @case ('pending') {
                    <span class="badge bg-warning text-dark">
                      <span class="spinner-border spinner-border-sm me-1" style="width:.6rem;height:.6rem"></span>
                      En cola...
                    </span>
                  }
                  @case ('processing') {
                    <span class="badge bg-info text-dark">
                      <span class="spinner-border spinner-border-sm me-1" style="width:.6rem;height:.6rem"></span>
                      Clasificando...
                    </span>
                  }
                  @case ('error') {
                    <span class="badge bg-danger">
                      <i class="bi bi-exclamation-circle me-1"></i>Error al clasificar
                    </span>
                  }
                  @default {
                    @if (doc.categories.length === 0) {
                      <span class="text-muted small">Sin categor\xEDas</span>
                    }
                    @for (cat of doc.categories; track cat.category) {
                      <span class="badge me-1 mb-1 category-badge"
                        [class.bg-primary]="cat.score >= 80"
                        [class.bg-info]="cat.score >= 50 && cat.score < 80"
                        [class.bg-secondary]="cat.score < 50">
                        {{ cat.category }} {{ cat.score }}%
                      </span>
                    }
                  }
                }
              </td>
              <td class="text-muted small text-nowrap">
                {{ doc.uploaded_at | date:'dd/MM/yyyy HH:mm' }}
              </td>
              <td class="text-end text-nowrap">
                <button class="btn btn-outline-primary btn-sm me-1"
                  title="Descargar" (click)="download(doc)"
                  [disabled]="doc.status !== 'done' && doc.categories.length === 0">
                  <i class="bi bi-download"></i>
                </button>
                <button class="btn btn-outline-danger btn-sm"
                  title="Eliminar" (click)="deleteOne(doc.id)">
                  <i class="bi bi-trash"></i>
                </button>
              </td>
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
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(Dashboard, { className: "Dashboard", filePath: "src/app/pages/dashboard/dashboard.ts", lineNumber: 18 });
})();
export {
  Dashboard
};
//# sourceMappingURL=chunk-3N6XN6C7.js.map
