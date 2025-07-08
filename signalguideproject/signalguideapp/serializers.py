# signalguideapp/serializers.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import SignalGuide, JobType

# SignalGuide 序列化器
class SignalGuideSerializer(serializers.ModelSerializer):
    job_type_display = serializers.CharField(source='job_type.name', read_only=True)
    
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