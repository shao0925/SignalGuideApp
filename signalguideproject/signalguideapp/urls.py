from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SignalGuideViewSet, home

router = DefaultRouter()
router.register(r'signal-guides', SignalGuideViewSet)

urlpatterns = [
    path('', home),  # 加這行作為首頁
    path('', include(router.urls)),
]
