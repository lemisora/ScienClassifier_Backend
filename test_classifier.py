"""
Test rápido del clasificador — modo keyword y zero_shot.
Ejecutar desde ScienClassifier_Backend/:
    mise exec -- python test_classifier.py
"""

import sys
sys.path.insert(0, ".")

from worker.classifier import classify

# ── Textos de prueba ──────────────────────────────────────────────────────────

TESTS = [
    {
        "label": "Tardigrados (debe → biología)",
        "expected": "biología",
        "text": """
        Tardigrades, commonly known as water bears, are microscopic aquatic animals
        belonging to the phylum Tardigrada. These organisms are renowned for their
        extraordinary ability to survive extreme environmental conditions through
        cryptobiosis, a state in which metabolic activity is reversibly suspended.
        During desiccation, tardigrades lose almost all body water and enter a
        dormant state called anhydrobiosis. Their DNA repair mechanisms and
        protective proteins such as trehalose and intrinsically disordered proteins
        are key to survival. Species like Ramazzottius varieornatus and
        Hypsibius exemplaris have been used as model organisms in studies of
        extremophile biology, genome sequencing, and evolutionary adaptation.
        ISSN 1234-5679
        """,
    },
    {
        "label": "Red neuronal / deep learning (debe → computación)",
        "expected": "computación",
        "text": """
        In this paper we present a novel deep learning architecture based on
        transformer networks for natural language processing tasks. Our model
        achieves state-of-the-art results on multiple benchmark datasets using
        self-attention mechanisms and gradient descent optimization. We trained
        the neural network on a GPU cluster using distributed computing with
        PyTorch. The algorithm outperforms previous machine learning baselines
        including support vector machines and random forests. The dataset
        contains 1.2 million labeled examples for text classification and
        regression tasks.
        ISSN 1234-5679
        """,
    },
    {
        "label": "Mecánica cuántica (debe → física)",
        "expected": "física",
        "text": """
        We investigate the quantum entanglement properties of photon pairs
        generated via spontaneous parametric down-conversion. The wave function
        collapse and Schrödinger equation solutions are analyzed under relativistic
        corrections. Our experiments measure the electromagnetic field interactions
        at the quantum level, confirming predictions of quantum electrodynamics.
        The Hamiltonian formalism is applied to describe particle-wave duality in
        the double-slit experiment. Results show strong correlation with quantum
        mechanics predictions for spin-1/2 particles and Higgs boson decay channels.
        ISSN 1234-5679
        """,
    },
    {
        "label": "Ensayo clínico oncología (debe → medicina)",
        "expected": "medicina",
        "text": """
        This randomized double-blind clinical trial evaluates the efficacy of
        pembrolizumab versus standard chemotherapy in patients with metastatic
        non-small cell lung cancer. A total of 520 participants were enrolled
        across 12 hospital sites. The primary endpoint was overall survival at
        24 months. Tumor biopsy samples were analyzed for biomarker expression.
        Patients receiving immunotherapy showed significantly reduced mortality
        and improved quality of life scores. Adverse events included infection,
        fatigue and immune-related pathology. Dosage was adjusted based on
        patient body weight and blood glucose levels.
        ISSN 1234-5679
        """,
    },
    {
        "label": "Síntesis orgánica (debe → química)",
        "expected": "química",
        "text": """
        We report the synthesis and characterization of a novel polymer catalyst
        for the oxidation of aromatic compounds. The reaction mechanism involves
        nucleophilic substitution at the carbon center, forming a stable
        intermediate ion. Spectroscopic analysis via chromatography and NMR
        confirms the molecular structure of the product. The catalyst achieves
        95% yield in aqueous solution at neutral pH, outperforming conventional
        acid-base reagents. Thermochemical measurements show an exothermic
        reaction enthalpy of −142 kJ/mol. The compound exhibits no cytotoxicity
        in preliminary biological assays.
        ISSN 1234-5679
        """,
    },
]

# ── Runner ────────────────────────────────────────────────────────────────────

def run(mode: str):
    print(f"\n{'='*60}")
    print(f"  MODO: {mode.upper()}")
    print(f"{'='*60}")
    passed = 0
    for t in TESTS:
        result = classify(t["text"], mode=mode)
        cats = result["categories"]
        top = cats[0]["category"] if cats else "—"
        top_score = cats[0]["score"] if cats else 0
        ok = top == t["expected"]
        if ok:
            passed += 1
        status = "✓ PASS" if ok else "✗ FAIL"
        print(f"\n  {status}  {t['label']}")
        print(f"         Esperado : {t['expected']}")
        print(f"         Obtenido : {top}  (score={top_score:.4f})")
        if len(cats) > 1:
            others = ", ".join(f"{c['category']}={c['score']:.3f}" for c in cats[1:3])
            print(f"         Otros    : {others}")
    print(f"\n  Resultado: {passed}/{len(TESTS)} correctos\n")
    return passed


if __name__ == "__main__":
    kw_score = run("keyword")

    print("\n" + "─"*60)
    print("  Cargando modelo zero-shot (puede tardar ~30s la 1ª vez)...")
    print("─"*60)
    zs_score = run("zero_shot")

    print(f"\n{'='*60}")
    print(f"  RESUMEN FINAL")
    print(f"  keyword   : {kw_score}/{len(TESTS)}")
    print(f"  zero_shot : {zs_score}/{len(TESTS)}")
    print(f"{'='*60}\n")
