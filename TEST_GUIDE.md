# Guide des Tests Unitaires

## Backend Tests (Java/Spring Boot)

### Frameworks Utilisés
- **JUnit 5 (Jupiter)** - Framework de test standard Java
- **Mockito** - Mock et spy des dépendances
- **AssertJ** - Assertions fluides
- **TestContainers** - Tests d'intégration avec BD

### Services Backend

#### 1. Product Service
**Tests créés:**
- `ProductServiceTest.java` - Tests unitaires du service
- `ProductControllerTest.java` - Tests du contrôleur REST

**Tests couverts:**
- ✅ Créer un produit
- ✅ Récupérer un produit par ID
- ✅ Récupérer tous les produits
- ✅ Mettre à jour un produit
- ✅ Supprimer un produit
- ✅ Gestion des erreurs (produit non trouvé)
- ✅ Validation des requêtes HTTP

#### 2. Order Service
**Tests créés:**
- `OrderServiceTest.java` - Tests unitaires du service
- `OrderControllerTest.java` - Tests du contrôleur REST

**Tests couverts:**
- ✅ Créer une commande
- ✅ Récupérer une commande
- ✅ Récupérer toutes les commandes
- ✅ Mettre à jour le statut
- ✅ Calculer le prix total
- ✅ Gestion des erreurs

#### 3. Inventory Service
**Tests créés:**
- `InventoryServiceTest.java` - Tests unitaires du service
- `InventoryControllerTest.java` - Tests du contrôleur REST

**Tests couverts:**
- ✅ Vérifier la disponibilité du stock
- ✅ Récupérer l'inventaire par SKU
- ✅ Récupérer tout l'inventaire
- ✅ Augmenter/Diminuer la quantité
- ✅ Gestion des erreurs

#### 4. Notification Service
**Tests créés:**
- `NotificationServiceTest.java` - Tests unitaires du service

**Tests couverts:**
- ✅ Envoyer un email de confirmation
- ✅ Formater le sujet de l'email
- ✅ Formater le corps de l'email
- ✅ Validation des destinataires

### Exécuter les tests Backend

#### Tous les tests
```bash
cd backend
mvn test
```

#### Tests d'un service spécifique
```bash
# Product Service
mvn test -pl product-service

# Order Service
mvn test -pl order-service

# Inventory Service
mvn test -pl inventory-service

# Notification Service
mvn test -pl notification-service
```

#### Tests avec rapport de couverture
```bash
mvn test jacoco:report
# Rapport disponible dans: target/site/jacoco/index.html
```

#### Tests avec output détaillé
```bash
mvn test -Dorg.slf4j.simpleLogger.defaultLogLevel=debug
```

---

## Frontend Tests (Angular)

### Frameworks Utilisés
- **Jasmine** - Framework de test BDD
- **Karma** - Test runner
- **Angular Testing Utilities** - TestBed, MockService

### Tests du Frontend

#### 1. Login Component
**Tests créés:**
- `login.component.spec.ts`

**Tests couverts:**
- ✅ Créer le composant
- ✅ Initialiser avec nom d'utilisateur admin
- ✅ Afficher erreur avec identifiants vides
- ✅ Connexion avec identifiants valides
- ✅ Définir le rôle ADMIN
- ✅ Définir le rôle USER
- ✅ Connexion rapide admin

#### 2. Product Service
**Tests créés:**
- `product.service.spec.ts`

**Tests couverts:**
- ✅ Créer le service
- ✅ Récupérer tous les produits
- ✅ Récupérer produit par ID
- ✅ Créer un produit
- ✅ Mettre à jour un produit
- ✅ Supprimer un produit

### Exécuter les tests Frontend

#### Tests une seule fois
```bash
cd frontend
npm test -- --watch=false --browsers=ChromeHeadless
```

#### Tests en mode watch (développement)
```bash
cd frontend
npm test
```

#### Tests avec rapport de couverture
```bash
cd frontend
npm test -- --code-coverage --watch=false
# Rapport: coverage/index.html
```

#### Tests spécifique
```bash
# Login Component tests only
npm test -- --include='**/login.component.spec.ts'

# Product Service tests only
npm test -- --include='**/product.service.spec.ts'
```

---

## Bonnes Pratiques

### 1. Anatomie d'un test
```java
@Test
@DisplayName("Description claire du test")
void testNomMethode() {
    // GIVEN - Préparation des données
    String username = "admin";
    
    // WHEN - Exécution
    boolean result = service.isValidUsername(username);
    
    // THEN - Vérification
    assertThat(result).isTrue();
}
```

### 2. Naming Conventions
- Classe test: `{ClasseOriginal}Test.java`
- Méthode test: `test{NomMethode}` ou `{NomMethode}_should{ExpectedBehavior}`

### 3. Coverage Targets
- Minimum: 70% de couverture
- Cible: 80-90% de couverture
- Focus sur logique métier, pas les getters/setters

### 4. Assertions Efficaces
```java
// ✅ BON - Assertions fluides et lisibles
assertThat(product)
    .isNotNull()
    .hasFieldOrPropertyWithValue("name", "Nike")
    .hasFieldOrPropertyWithValue("price", BigDecimal.valueOf(150.00));

// ❌ MAUVAIS - Assertions classiques
assertNotNull(product);
assertEquals("Nike", product.getName());
assertEquals(new BigDecimal("150.00"), product.getPrice());
```

### 5. Mock vs Spy
```java
// Mock - Objet complètement simulé
@Mock
private ProductRepository productRepository;

// Spy - Objet réel avec certaines méthodes mockées
@Spy
private ProductService productService;
```

---

## Pipeline CI/CD

Les tests s'exécutent automatiquement lors:
- Chaque commit
- Chaque pull request
- Avant déploiement

Build échoue si:
- ❌ Erreur dans les tests
- ❌ Couverture < 70%
- ❌ Violations de code

---

## Troubleshooting

### Backend
**Problème:** Tests lents
```bash
# Solution: Exécuter en parallèle
mvn test -DthreadCount=4
```

**Problème:** Erreur de dépendances
```bash
# Solution: Nettoyer les dépendances
mvn clean test
```

### Frontend
**Problème:** Chrome not found
```bash
# Solution: Utiliser ChromeHeadless ou Firefox
npm test -- --browsers=ChromeHeadless
```

**Problème:** Tests timeout
```bash
# Solution: Augmenter le timeout dans karma.conf.js
browserNoActivityTimeout: 60000
```

---

## Prochaines Étapes

1. ✅ Tests unitaires créés
2. ⏳ Tests d'intégration (TestContainers)
3. ⏳ Tests E2E (Cypress/Selenium)
4. ⏳ Performance tests (JMH)
5. ⏳ Couverture de code > 80%
