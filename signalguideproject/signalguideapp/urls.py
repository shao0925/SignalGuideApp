# signalguideapp/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SignalGuideViewSet, JobTypeViewSet, CustomTokenView, DeviceViewSet, home, create_user_view, change_password, devices_by_guide

router = DefaultRouter()
router.register(r'signal-guides', SignalGuideViewSet)
router.register(r'jobtypes', JobTypeViewSet)
router.register(r'devices', DeviceViewSet)


urlpatterns = [
    path('', home),
    path('', include(router.urls)),
    path('token/', CustomTokenView.as_view(), name='token_obtain_pair'),
    path('change_password/', change_password, name='change_password'),
    path('create_user/', create_user_view, name='create_user'),
    path('devices/by-guide/<int:guide_id>/', devices_by_guide, name='devices-by-guide'),
]
