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

# 作業類別模型（JobType）
class JobType(models.Model):
    name = models.CharField("作業類別名稱", max_length=50, unique=True)

    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    class Meta:
        verbose_name = "作業類別"
        verbose_name_plural = "作業類別列表"
        ordering = ['name']

    def __str__(self):
        return self.name

# 工作說明書模型（SignalGuide）
class SignalGuide(models.Model):

    job_type = models.ForeignKey(
        JobType,
        verbose_name="作業類別",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='guides'
    )
    system = models.CharField("系統", max_length=100)
    subsystem = models.CharField("子系統", max_length=100, blank=True)
    equipment_type = models.CharField("設備類別", max_length=100, blank=True)
    doc_number = models.CharField("文件編號", max_length=50, unique=True)
    title = models.CharField("文件名稱", max_length=200)
    department = models.CharField("權責股", max_length=100, blank=True)
    owner = models.CharField("負責人員", max_length=100, blank=True)
    file = models.FileField("上傳檔案", upload_to='manuals/', blank=True)
    is_pinned = models.BooleanField("是否置頂", default=False)

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


# 故障處理圖片模型（ProcedureStep）
class ProcedureStep(models.Model):
    fault = models.ForeignKey(FaultCase, on_delete=models.CASCADE, related_name='steps')
    file = models.FileField("步驟相關圖片或PDF", upload_to='procedure_files/')
    order = models.PositiveIntegerField("排序順序", default=0)  # 拖曳排序使用

    # 加入時間戳記
    created_at = models.DateTimeField("建立時間", auto_now_add=True)
    updated_at = models.DateTimeField("最後更新", auto_now=True)

    class Meta:
        ordering = ['order']  # 預設依照拖曳順序顯示
        verbose_name = '故障處理圖片'
        verbose_name_plural = '故障處理圖片列表'

    def __str__(self):
        return f"步驟檔案 ID: {self.id}"