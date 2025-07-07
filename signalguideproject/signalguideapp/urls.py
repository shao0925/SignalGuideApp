from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SignalGuideViewSet, home, create_user_view, CustomTokenView

router = DefaultRouter()
router.register(r'signal-guides', SignalGuideViewSet)

urlpatterns = [
    path('', home),  # 加這行作為首頁
    path('', include(router.urls)),
    path('create_user/', create_user_view, name='create_user'),
    path('token/', CustomTokenView.as_view(), name='token_obtain_pair'),
]
