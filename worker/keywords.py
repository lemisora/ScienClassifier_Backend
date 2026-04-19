# Keywords por categoría — español, inglés y términos técnicos mixtos.
# Ajustar según los artículos reales que se vayan subiendo al sistema.

CATEGORIES: dict[str, list[str]] = {
    "matemáticas": [
        # español
        "ecuación", "álgebra", "derivada", "integral", "matriz", "teorema",
        "demostración", "función", "variable", "cálculo", "probabilidad",
        "estadística", "geometría", "trigonometría", "logaritmo", "vector",
        "espacio vectorial", "conjunto", "límite", "serie", "sucesión",
        "polinomio", "determinante", "eigenvalor", "topología", "análisis",
        # inglés / mixto
        "equation", "algebra", "derivative", "integral", "matrix", "theorem",
        "proof", "calculus", "probability", "statistics", "geometry",
        "logarithm", "eigenvector", "eigenvalue", "topology", "lemma",
        "corollary", "polynomial", "stochastic", "linear algebra",
    ],

    "física": [
        # español — términos específicos de física, evitar genéricos
        "velocidad", "masa", "partícula", "onda", "longitud de onda",
        "electrón", "fotón", "relatividad", "gravedad", "termodinámica",
        "entropía", "magnetismo", "colisión", "momento angular", "aceleración",
        "átomo", "núcleo atómico", "plasma", "mecánica cuántica", "óptica",
        "electromagnetismo", "fuerza gravitacional", "campo eléctrico",
        "campo magnético", "mecánica clásica", "astrofísica", "cosmología",
        "espectro", "difracción", "refracción", "conductividad", "resistividad",
        # inglés / mixto
        "velocity", "mass", "particle", "wave", "electron", "photon",
        "relativity", "gravity", "thermodynamics", "entropy", "magnetism",
        "quantum mechanics", "quantum", "momentum", "acceleration",
        "nucleus", "laser", "superconductor", "Higgs boson", "dark matter",
        "string theory", "electromagnetic", "astrophysics", "cosmology",
        "diffraction", "refraction", "conductivity", "resistivity",
        "Newtonian", "Hamiltonian", "Lagrangian", "Schrödinger",
    ],

    "química": [
        # español
        "molécula", "reacción", "elemento", "compuesto", "enlace",
        "oxidación", "solución", "catalizador", "ion", "ácido", "base",
        "pH", "polímero", "síntesis", "concentración", "titulación",
        "electrólisis", "precipitado", "reactivo", "producto", "isómero",
        "espectroscopia", "cromatografía", "nanomaterial", "surfactante",
        # inglés / mixto
        "molecule", "reaction", "element", "compound", "bond", "oxidation",
        "solution", "catalyst", "acid", "base", "polymer", "synthesis",
        "concentration", "electrolysis", "reagent", "isomer",
        "spectroscopy", "chromatography", "nanomaterial", "ligand",
        "thermochemistry", "electrochemistry", "organic", "inorganic",
    ],

    "biología": [
        # español
        "célula", "proteína", "gen", "evolución", "organismo", "ADN",
        "ARN", "enzima", "metabolismo", "especie", "tejido", "órgano",
        "ecosistema", "fotosíntesis", "mutación", "cromosoma", "membrana",
        "mitocondria", "neurona", "bacteria", "virus", "hongo", "planta",
        "reproducción", "herencia", "fenotipo", "genotipo", "biodiversidad",
        # inglés / mixto
        "cell", "protein", "gene", "evolution", "organism", "DNA", "RNA",
        "enzyme", "metabolism", "species", "tissue", "ecosystem",
        "photosynthesis", "mutation", "chromosome", "mitochondria",
        "neuron", "bacteria", "virus", "genome", "phenotype", "genotype",
        "CRISPR", "bioinformatics", "proteomics", "sequencing",
    ],

    "computación": [
        # español
        "algoritmo", "red neuronal", "base de datos", "software", "hardware",
        "compilador", "sistema operativo", "red", "protocolo", "cifrado",
        "inteligencia artificial", "aprendizaje automático", "grafo",
        "árbol", "complejidad", "recursión", "paralelismo", "concurrencia",
        "memoria", "proceso", "hilo", "arquitectura", "microservicio",
        # inglés / mixto
        "algorithm", "neural network", "database", "compiler",
        "operating system", "network", "protocol", "encryption",
        "artificial intelligence", "machine learning", "deep learning",
        "graph", "tree", "complexity", "recursion", "parallelism",
        "concurrency", "architecture", "microservice", "API", "framework",
        "dataset", "clustering", "classification", "regression",
        "GPU", "CPU", "cloud", "distributed", "blockchain", "IoT",
    ],

    "ingeniería": [
        # español
        "diseño", "estructura", "material", "resistencia", "circuito",
        "señal", "control", "automatización", "manufactura", "proceso",
        "eficiencia", "optimización", "simulación", "prototipo", "sensor",
        "actuador", "robótica", "mecánica", "hidráulica", "neumática",
        "soldadura", "concreto", "acero", "puente", "turbina", "motor",
        # inglés / mixto
        "design", "structure", "material", "resistance", "circuit",
        "signal", "control", "automation", "manufacturing", "efficiency",
        "optimization", "simulation", "prototype", "sensor", "actuator",
        "robotics", "mechanics", "hydraulics", "bridge", "turbine",
        "engine", "CAD", "CAM", "finite element", "PLC", "SCADA",
    ],

    "medicina": [
        # español
        "enfermedad", "diagnóstico", "tratamiento", "paciente", "síntoma",
        "fármaco", "dosis", "cirugía", "terapia", "vacuna", "anticuerpo",
        "infección", "cáncer", "tumor", "tejido", "órgano", "sangre",
        "presión arterial", "glucosa", "epidemiología", "ensayo clínico",
        "placebo", "resonancia", "tomografía", "ultrasonido", "biopsia",
        "salud", "clínica", "médico", "hospital", "estrés", "ansiedad",
        "depresión", "psiquiatría", "psicología", "trastorno", "bienestar",
        "rehabilitación", "neurología", "cardiología", "inmunología",
        "biomédico", "biomarker", "muestra", "sujeto", "participante",
        # inglés / mixto
        "disease", "diagnosis", "treatment", "patient", "symptom",
        "drug", "dosage", "surgery", "therapy", "vaccine", "antibody",
        "infection", "cancer", "tumor", "blood", "clinical trial",
        "placebo", "MRI", "CT scan", "biopsy", "mortality", "morbidity",
        "randomized", "double-blind", "biomarker", "pathology",
        "stress", "coping", "mental health", "anxiety", "depression",
        "psychiatric", "psychological", "wellbeing", "health", "nurse",
        "physician", "hospital", "subjects", "participants", "cohort",
        "biomedical", "neurology", "cardiology", "immunology", "chronic",
    ],

    "ciencias sociales": [
        # español
        "sociedad", "cultura", "economía", "política", "derecho",
        "educación", "psicología", "comportamiento", "población", "encuesta",
        "entrevista", "etnografía", "discurso", "identidad", "género",
        "desigualdad", "migración", "globalización", "democracia",
        "institución", "mercado", "pobreza", "bienestar", "conflicto",
        "comunidad", "grupo", "percepción", "actitud", "motivación",
        "aprendizaje", "docente", "estudiante", "organización", "liderazgo",
        "trabajo", "empleo", "familia", "religión", "historia", "filosofía",
        # inglés / mixto
        "society", "culture", "economy", "politics", "law", "education",
        "psychology", "behavior", "population", "survey", "interview",
        "ethnography", "discourse", "identity", "gender", "inequality",
        "migration", "globalization", "democracy", "market", "poverty",
        "welfare", "qualitative", "quantitative", "regression analysis",
        "community", "perception", "attitude", "motivation", "learning",
        "organization", "leadership", "team", "social", "human", "group",
        "isolated", "extreme environment", "expedition", "crew", "mission",
    ],
}

# Score mínimo para mostrar una categoría al usuario (0.0 - 1.0)
SCORE_THRESHOLD = 0.20
