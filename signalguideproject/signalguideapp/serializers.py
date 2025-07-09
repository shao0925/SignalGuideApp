# signalguideapp/serializers.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import SignalGuide, JobType, Device, FaultCase

# SignalGuide 序列化器
class SignalGuideSerializer(serializers.ModelSerializer):
    job_type_display = serializers.CharField(source='job_type.name', read_only=True)
    job_type_name = serializers.CharField(source='job_type.name', read_only=True)  # ← 加這行

    class Meta:
        model = SignalGuide
        fields = '__all__'

# 自訂登入序列化器：加入 name、role、employee_id
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['name'] = user.name
        token['role'] = user.role
        token['employee_id'] = user.employee_id
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['name'] = self.user.name
        data['role'] = self.user.role
        data['employee_id'] = self.user.employee_id
        return data

# JobType 序列化器
class JobTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobType
        fields = ['id', 'name']

# Device 序列化器
class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = '__all__'

# FaultCase 序列化器
class FaultCaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = FaultCase
        fields = '__all__'