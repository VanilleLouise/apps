# admin.py
from django.contrib import admin
from .models import Utilisateur, Thematique, Evenement

admin.site.register(Utilisateur)
admin.site.register(Thematique)
admin.site.register(Evenement)

# serializers.py
from rest_framework import serializers
from .models import Utilisateur, Thematique, Evenement

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = '__all__'

class ThematiqueSerializer(serializers.ModelSerializer):
    class Meta:
        model = Thematique
        fields = '__all__'

class EvenementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Evenement
        fields = '__all__'

# views.py
from rest_framework import viewsets
from .models import Utilisateur, Thematique, Evenement
from .serializers import UtilisateurSerializer, ThematiqueSerializer, EvenementSerializer

class UtilisateurViewSet(viewsets.ModelViewSet):
    queryset = Utilisateur.objects.all()
    serializer_class = UtilisateurSerializer

class ThematiqueViewSet(viewsets.ModelViewSet):
    queryset = Thematique.objects.all()
    serializer_class = ThematiqueSerializer

class EvenementViewSet(viewsets.ModelViewSet):
    queryset = Evenement.objects.all()
    serializer_class = EvenementSerializer

# urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UtilisateurViewSet, ThematiqueViewSet, EvenementViewSet

router = DefaultRouter()
router.register(r'utilisateurs', UtilisateurViewSet)
router.register(r'thematiques', ThematiqueViewSet)
router.register(r'evenements', EvenementViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
