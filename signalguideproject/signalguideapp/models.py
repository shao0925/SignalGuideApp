import re
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.exceptions import ValidationError

# 自訂使用者管理器
class CustomUserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, employee_id, name, password=None, **extra_fields):
        if not employee_id:
            raise ValueError('必須提供員工編號')
        if not name:
            raise ValueError('必須提供姓名')
        if not password:
            raise ValueError('必須提供密碼')
        
        if len(password) < 6 or not re.search(r'[a-zA-Z]', password):
            raise ValueError('密碼至少需 6 碼，且包含至少一個英文字母')
        
        user = self.model(employee_id=employee_id, name=name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, employee_id, name, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(employee_id, name, password, **extra_fields)

# 驗證五位數員工編號
def validate_five_digit_id(value):
    if value == 'A0000':
        return  # 特例通過
    if not re.fullmatch(r'\d{5}', value):
        raise ValidationError('員工編號必須是五位數數字（例如 00001）')

# 自訂使用者模型（員工帳號）
class CustomUser(AbstractUser):
    username = None
    employee_id = models.CharField(
        max_length=5,
        unique=True,
        verbose_name='員工編號',
        validators=[validate_five_digit_id]
    )
    name = models.CharField(max_length=100, verbose_name='姓名')

    ROLE_CHOICES = (
        ('A', '管理者'),
        ('B', '查詢者'),
    )
    role = models.CharField(max_length=1, choices=ROLE_CHOICES, default='B')

    USERNAME_FIELD = 'employee_id'
    REQUIRED_FIELDS = ['name']

    objects = CustomUserManager()

    def __str__(self):
        return f"{self.employee_id} - {self.name} ({self.role})"
    
    class Meta:
        verbose_name = '員工帳號'
        verbose_name_plural = '帳號管理'
        ordering = ['employee_id']

# 工作說明書模型（SignalGuide）
class SignalGuide(models.Model):
    # 作業類別選項（主畫面五大分類）
    JOB_TYPE_CHOICES = [
        ('行政管理', '行政管理'),
        ('故障檢修', '故障檢修'),
        ('特別檢修', '特別檢修'),
        ('預防檢修', '預防檢修'),
        ('維修管理', '維修管理'),
    ]

    job_type = models.CharField("作業類別", max_length=20, choices=JOB_TYPE_CHOICES)
    system = models.CharField("系統", max_length=100)
    subsystem = models.CharField("子系統", max_length=100, blank=True)
    equipment_type = models.CharField("設備類別", max_length=100, blank=True)
    doc_number = models.CharField("文件編號", max_length=50, unique=True)
    title = models.CharField("文件名稱", max_length=200)
    department = models.CharField("權責股", max_length=100, blank=True)
    owner = models.CharField("負責人員", max_length=100, blank=True)
    file = models.FileField("上傳檔案", upload_to='manuals/', blank=True)
    is_frequently_used = models.BooleanField("是否為熱門文件", default=False)

    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    def __str__(self):
        return f"{self.doc_number} - {self.title}"

    class Meta:
        verbose_name = '工作說明書'
        verbose_name_plural = '工作說明書列表'
        ordering = ['job_type', 'system', 'title']

# 設備模型（Device）
class Device(models.Model):
    guide = models.ForeignKey(SignalGuide, on_delete=models.CASCADE, related_name='devices')
    name = models.CharField("設備名稱", max_length=200)
    
    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    def __str__(self):
        return self.name
    
    class Meta:
        verbose_name = '設備'
        verbose_name_plural = '設備列表'

# 設備故障案例模型（FaultCase）
class FaultCase(models.Model):
    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name='faults')
    description = models.TextField("故障徵狀")

    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    def __str__(self):
        return self.description[:30]
    
    class Meta:
        verbose_name = '設備故障案例'
        verbose_name_plural = '設備故障案例列表'


# 故障處理步驟模型（ProcedureStep）
class ProcedureStep(models.Model):
    fault = models.ForeignKey(FaultCase, on_delete=models.CASCADE, related_name='steps')
    step_order = models.PositiveIntegerField("步驟順序")
    instruction = models.TextField("處理說明")

    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    class Meta:
        ordering = ['step_order']
        verbose_name = '故障處理步驟'
        verbose_name_plural = '故障處理步驟列表'

    def __str__(self):
        return f"Step {self.step_order}"