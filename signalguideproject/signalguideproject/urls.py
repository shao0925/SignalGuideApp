# signalguideproject/urls.py
from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('signalguideapp.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),  # 登入
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),  # 續約
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)