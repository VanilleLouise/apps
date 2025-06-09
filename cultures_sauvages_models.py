# Django Models pour la base cultures_sauvages.db
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager

class UtilisateurManager(BaseUserManager):
    def create_user(self, email, nom, prenom, password=None, **extra_fields):
        if not email:
            raise ValueError('Un email est requis')
        email = self.normalize_email(email)
        user = self.model(email=email, nom=nom, prenom=prenom, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, nom, prenom, password=None, **extra_fields):
        extra_fields.setdefault('statut', 'admin')
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, nom, prenom, password, **extra_fields)

class Utilisateur(AbstractBaseUser, PermissionsMixin):
    STATUTS = [
        ('admin', 'Admin'),
        ('membre_actif', 'Membre Actif'),
        ('benevole', 'Bénévole'),
        ('adherent', 'Adhérent'),
    ]

    email = models.EmailField(unique=True)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20, blank=True, null=True)
    date_naissance = models.DateField(blank=True, null=True)
    ville = models.CharField(max_length=100, blank=True, null=True)
    statut = models.CharField(max_length=20, choices=STATUTS, default='adherent')
    disponibilites = models.JSONField(blank=True, null=True)
    competences_partagees = models.TextField(blank=True, null=True)
    interets = models.TextField(blank=True, null=True)
    contrepartie_souhaitee = models.TextField(blank=True, null=True)
    date_inscription = models.DateTimeField(auto_now_add=True)
    derniere_connexion = models.DateTimeField(blank=True, null=True)
    actif = models.BooleanField(default=True)
    date_derniere_cotisation = models.DateField(blank=True, null=True)
    montant_derniere_cotisation = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nom', 'prenom']

    objects = UtilisateurManager()

    def __str__(self):
        return f"{self.prenom} {self.nom}"

class Thematique(models.Model):
    nom = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    couleur = models.CharField(max_length=7)
    icone = models.CharField(max_length=50)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nom

class Evenement(models.Model):
    TYPE_CHOICES = [
        ('atelier', 'Atelier'),
        ('chantier', 'Chantier'),
        ('reunion', 'Réunion'),
        ('formation', 'Formation'),
        ('festivite', 'Festivité'),
        ('autre', 'Autre'),
    ]
    STATUT_CHOICES = [
        ('planifie', 'Planifié'),
        ('confirme', 'Confirmé'),
        ('en_cours', 'En cours'),
        ('termine', 'Terminé'),
        ('annule', 'Annulé'),
    ]

    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    date_debut = models.DateTimeField()
    date_fin = models.DateTimeField(blank=True, null=True)
    duree_estimee = models.IntegerField(blank=True, null=True)
    lieu = models.CharField(max_length=200, blank=True, null=True)
    adresse = models.TextField(blank=True, null=True)
    thematique = models.ForeignKey(Thematique, on_delete=models.SET_NULL, null=True, blank=True)
    type_evenement = models.CharField(max_length=20, choices=TYPE_CHOICES)
    nombre_places_max = models.IntegerField(blank=True, null=True)
    nombre_inscrits = models.IntegerField(default=0)
    inscription_obligatoire = models.BooleanField(default=False)
    tarif = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    frais_participation = models.TextField(blank=True, null=True)
    besoins_competences = models.TextField(blank=True, null=True)
    materiels_necessaires = models.TextField(blank=True, null=True)
    materiels_fournis = models.TextField(blank=True, null=True)
    organisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE)
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='planifie')
    publique = models.BooleanField(default=True)
    notes_organisation = models.TextField(blank=True, null=True)
    retour_experience = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.titre
