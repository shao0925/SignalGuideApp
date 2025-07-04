from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, SignalGuide

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ('employee_id', 'name', 'role', 'is_staff', 'is_active')
    list_filter = ('role', 'is_staff', 'is_superuser', 'is_active')

    fieldsets = (
        (None, {'fields': ('employee_id', 'name', 'password', 'role')}),
        ('權限', {'fields': ('is_staff', 'is_active', 'is_superuser', 'groups', 'user_permissions')}),
        ('其他資訊', {'fields': ('last_login', 'date_joined')}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('employee_id', 'name', 'role', 'password1', 'password2', 'is_staff', 'is_active')}
        ),
    )

    search_fields = ('employee_id', 'name')
    ordering = ('employee_id',)

admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(SignalGuide)
