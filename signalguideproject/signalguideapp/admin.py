from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, SignalGuide, Device, FaultCase, ProcedureStep

# ----------- 使用者管理後台 -----------
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

# ----------- 工作說明書管理後台 -----------
class SignalGuideAdmin(admin.ModelAdmin):
    list_display = ('doc_number', 'title', 'job_type', 'system', 'department', 'owner', 'created_at', 'is_frequently_used')
    list_filter = ('job_type', 'system', 'department', 'is_frequently_used')
    search_fields = ('doc_number', 'title', 'system', 'subsystem', 'equipment_type', 'owner')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')

# ----------- 設備管理後台 -----------
class DeviceAdmin(admin.ModelAdmin):
    list_display = ('name', 'guide', 'created_at')
    list_filter = ('guide__job_type',)
    search_fields = ('name', 'guide__title')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')

# ----------- 故障案例管理後台 -----------
class FaultCaseAdmin(admin.ModelAdmin):
    list_display = ('description_short', 'device', 'created_at')
    list_filter = ('device__guide__job_type',)
    search_fields = ('description', 'device__name')
    ordering = ('-created_at',)
    readonly_fields = ('created_at', 'updated_at')

    def description_short(self, obj):
        return obj.description[:30] + ('...' if len(obj.description) > 30 else '')
    description_short.short_description = '故障徵狀'

# ----------- 處理步驟管理後台 -----------
class ProcedureStepAdmin(admin.ModelAdmin):
    list_display = ('step_order', 'instruction_short', 'fault', 'created_at')
    list_filter = ('fault__device__guide__job_type',)
    search_fields = ('instruction', 'fault__description')
    ordering = ('fault', 'step_order')
    readonly_fields = ('created_at', 'updated_at')

    def instruction_short(self, obj):
        return obj.instruction[:30] + ('...' if len(obj.instruction) > 30 else '')
    instruction_short.short_description = '處理說明'

# ----------- 註冊模型與對應後台管理類 -----------
admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(SignalGuide, SignalGuideAdmin)
admin.site.register(Device, DeviceAdmin)
admin.site.register(FaultCase, FaultCaseAdmin)
admin.site.register(ProcedureStep, ProcedureStepAdmin)
