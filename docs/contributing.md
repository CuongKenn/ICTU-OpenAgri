# Đóng Góp

Cảm ơn bạn đã quan tâm đến việc đóng góp cho ICTU-OpenAgri! 🎉

---

## Cách Đóng Góp

### 1. Fork Repository

```bash
# Fork trên GitHub, sau đó clone
git clone https://github.com/YOUR_USERNAME/ICTU-OpenAgri.git
cd ICTU-OpenAgri
git remote add upstream https://github.com/CuongKenn/ICTU-OpenAgri.git
```

### 2. Tạo Branch

```bash
# Sync với upstream
git fetch upstream
git checkout main
git merge upstream/main

# Tạo branch mới
git checkout -b feature/your-feature-name
```

### 3. Phát Triển

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Linux/macOS
# hoặc: .\venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Frontend
cd frontend
flutter pub get
```

### 4. Commit Changes

Sử dụng [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git add .
git commit -m "feat: add NDVI time-series chart"
```

**Commit types:**

| Type       | Mô tả                              |
| ---------- | ---------------------------------- |
| `feat`     | Tính năng mới                      |
| `fix`      | Sửa bug                            |
| `docs`     | Chỉ thay đổi documentation         |
| `style`    | Format code (không thay đổi logic) |
| `refactor` | Refactor code                      |
| `test`     | Thêm tests                         |
| `chore`    | Thay đổi build, CI, etc.           |

### 5. Push và Tạo Pull Request

```bash
git push origin feature/your-feature-name
```

Sau đó tạo Pull Request trên GitHub.

---

## Coding Standards

### Python (Backend)

```python
# Sử dụng type hints
def calculate_ndvi(red: float, nir: float) -> float:
    """
    Calculate NDVI from red and NIR bands.

    Args:
        red: Red band reflectance (0-1)
        nir: NIR band reflectance (0-1)

    Returns:
        NDVI value (-1 to 1)
    """
    return (nir - red) / (nir + red)

# Async functions cho I/O
async def fetch_weather(lat: float, lon: float) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/weather?lat={lat}&lon={lon}")
        return response.json()
```

**Tools:**

```bash
# Format code
black backend/

# Sort imports
isort backend/

# Lint
flake8 backend/
```

### Dart (Frontend)

```dart
// Sử dụng const constructors khi có thể
class FarmCard extends StatelessWidget {
  const FarmCard({
    super.key,
    required this.farm,
    this.onTap,
  });

  final Farm farm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**Tools:**

```bash
# Format code
dart format lib/

# Analyze
flutter analyze
```

---

## Project Structure

### Backend

```plaintext
backend/
├── app/
│   ├── domain/          # Entities, Repository Interfaces
│   ├── application/     # Services, Schemas
│   ├── infrastructure/  # Repositories, External APIs
│   └── presentation/    # Routes, Controllers
└── tests/
```

### Frontend

```plaintext
frontend/lib/
├── models/          # Data models
├── providers/       # State management
├── services/        # API services
├── screens/         # UI screens
└── widgets/         # Reusable widgets
```

---

## Testing

### Backend Tests

```bash
cd backend
pytest tests/ -v

# Với coverage
pytest tests/ --cov=app --cov-report=html
```

### Frontend Tests

```bash
cd frontend
flutter test

# Integration tests
flutter test integration_test/
```

---

## Documentation

Nếu bạn thay đổi API hoặc thêm tính năng mới:

1. Cập nhật docstrings trong code
2. Cập nhật files trong `docs/`
3. Test documentation locally:

```bash
pip install mkdocs-material
mkdocs serve
```

---

## Issues

### Báo Cáo Bug

Khi tạo issue, vui lòng cung cấp:

- [ ] Mô tả bug rõ ràng
- [ ] Các bước để reproduce
- [ ] Expected behavior
- [ ] Screenshots (nếu có)
- [ ] Environment (OS, Python/Flutter version)

### Feature Request

- [ ] Mô tả tính năng
- [ ] Use case / Why it's needed
- [ ] Possible implementation

---

## Code Review

Khi review Pull Request:

1. ✅ Code chạy được
2. ✅ Có tests cho logic mới
3. ✅ Code clean, readable
4. ✅ Không có security issues
5. ✅ Documentation updated

---

## License

Bằng việc đóng góp, bạn đồng ý rằng contributions của bạn sẽ được license theo [Apache 2.0 License](https://github.com/CuongKenn/ICTU-OpenAgri/blob/main/LICENSE).

---

## Cộng Đồng

- 📧 Email: [quoccuong59qc@gmail.com](mailto:quoccuong59qc@gmail.com)
- 🐛 Issues: [GitHub Issues](https://github.com/CuongKenn/ICTU-OpenAgri/issues)
- 📖 Discussions: [GitHub Discussions](https://github.com/CuongKenn/ICTU-OpenAgri/discussions)

---

Cảm ơn bạn đã đóng góp! 🙏
