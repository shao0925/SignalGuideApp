from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth import get_user_model
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import SignalGuide
from .serializers import CustomTokenObtainPairSerializer, SignalGuideSerializer
import re

# 自訂登入序列化器：加入 name、role、employee_id
class CustomTokenView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

# 自訂權限類別：僅 A 角色可以進行寫入操作
class IsAdminRole(BasePermission):
    def has_permission(self, request, view):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        return hasattr(request.user, 'role') and request.user.role == 'A'

User = get_user_model()

# 建立帳號：僅限 A 角色
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_user_view(request):
    if not hasattr(request.user, 'role') or request.user.role != 'A':
        return Response({'detail': '沒有權限新增帳號'}, status=status.HTTP_403_FORBIDDEN)

    data = request.data
    required_fields = ['employee_id', 'name', 'password', 'role']

    if not all(field in data for field in required_fields):
        return Response({'detail': '資料不完整'}, status=status.HTTP_400_BAD_REQUEST)

    emp_id = data['employee_id']
    if emp_id != 'A0000' and not re.fullmatch(r'\d{5}', emp_id):
        return Response({'detail': '員工編號必須是五位數數字（如 00001）'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.create_user(
            employee_id=data['employee_id'],
            name=data['name'],
            password=data['password'],
            role=data['role']
        )
        return Response({'detail': f'帳號 {user.employee_id} 建立成功'}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'detail': f'建立失敗：{str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

# SignalGuide ViewSet
class SignalGuideViewSet(viewsets.ModelViewSet):
    queryset = SignalGuide.objects.all()
    serializer_class = SignalGuideSerializer
    permission_classes = [IsAuthenticated, IsAdminRole]  # 加上自訂權限

def home(request):
    return HttpResponse("🎉 歡迎來到 Signal Guide 系統 API 後端")