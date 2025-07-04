from django.shortcuts import render
from rest_framework import viewsets
from .models import SignalGuide
from .serializers import SignalGuideSerializer
from django.http import HttpResponse
from rest_framework.permissions import IsAuthenticated

# Create your views here.
class SignalGuideViewSet(viewsets.ModelViewSet):
    queryset = SignalGuide.objects.all()
    serializer_class = SignalGuideSerializer
    permission_classes = [IsAuthenticated]

def home(request):
    return HttpResponse("🎉 歡迎來到 Signal Guide 系統 API 後端")