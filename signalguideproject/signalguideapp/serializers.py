# signalguideapp/serializers.py
from rest_framework import serializers
from .models import SignalGuide

class SignalGuideSerializer(serializers.ModelSerializer):
    class Meta:
        model = SignalGuide
        fields = '__all__'
