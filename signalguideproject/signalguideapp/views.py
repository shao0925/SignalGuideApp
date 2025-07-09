from django.shortcuts import render
from django.http import HttpResponse
from django.contrib.auth import get_user_model
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import SignalGuide, JobType, Device
from .serializers import CustomTokenObtainPairSerializer, SignalGuideSerializer, JobTypeSerializer, DeviceSerializer
import re

# Home view
def home(request):
    return HttpResponse("🎉 歡迎來到 Signal Guide 系統 API 後端")

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

# 修改密碼：僅限已登入使用者
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    data = request.data

    # old_password = data.get('old_password')
    new_password = data.get('new_password')
    
    '''
    if not user.check_password(old_password):
        return Response({'detail': '舊密碼錯誤'}, status=status.HTTP_400_BAD_REQUEST)
    '''
    
    if not new_password or len(new_password) < 6:
        return Response({'detail': '新密碼長度不足'}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()
    return Response({'detail': '密碼修改成功'}, status=status.HTTP_200_OK)

# SignalGuide ViewSet
class SignalGuideViewSet(viewsets.ModelViewSet):
    queryset = SignalGuide.objects.all()
    serializer_class = SignalGuideSerializer
    permission_classes = [IsAuthenticated, IsAdminRole]

    def get_queryset(self):
        queryset = SignalGuide.objects.all()
        job_type = self.request.query_params.get('job_type')
        is_pinned = self.request.query_params.get('is_pinned')

        if job_type is not None:
            queryset = queryset.filter(job_type__id=job_type)

        if is_pinned is not None:
            if is_pinned.lower() == 'true':
                queryset = queryset.filter(is_pinned=True)
            elif is_pinned.lower() == 'false':
                queryset = queryset.filter(is_pinned=False)

        return queryset.order_by('doc_number')


# JobType ViewSet
class JobTypeViewSet(viewsets.ModelViewSet):
    queryset = JobType.objects.all().order_by('created_at')  # 依建立時間新到舊排序
    serializer_class = JobTypeSerializer
    permission_classes = [IsAuthenticated, IsAdminRole]


# 取得所有工作說明書
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def devices_by_guide(request, guide_id):
    devices = Device.objects.filter(guide_id=guide_id)
    serializer = DeviceSerializer(devices, many=True)
    return Response(serializer.data)

# Device ViewSet
class DeviceViewSet(viewsets.ModelViewSet):
    queryset = Device.objects.all()
    serializer_class = DeviceSerializer
    permission_classes = [IsAuthenticated, IsAdminRole]
