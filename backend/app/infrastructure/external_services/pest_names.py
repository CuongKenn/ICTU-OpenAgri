# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Mapping from scientific names to Vietnamese common names for pests
"""

PEST_VIETNAMESE_NAMES = {
    # Rice pests (Asia/India/Vietnam)
    "Nilaparvata lugens": "Rầy nâu",
    "Sogatella furcifera": "Rầy lưng trắng",
    "Chilo suppressalis": "Sâu đục thân lúa",
    "Scirpophaga incertulas": "Sâu cuốn lá nhỏ",
    "Cnaphalocrocis medinalis": "Sâu cuốn lá lúa",
    "Leptocorisa oratorius": "Bọ xít hại lúa",
    "Dicladispa armigera": "Bọ cánh tơ",
    
    # Common agricultural pests (Global)
    "Sitophilus oryzae": "Mọt gạo",
    "Tribolium castaneum": "Mọt bột đỏ",
    "Acyrthosiphon pisum": "Rệp đậu Hà Lan",
    "Myzus persicae": "Rệp đào xanh",
    "Diabrotica virgifera": "Sâu rễ ngô phương Tây",
    "Helicoverpa armigera": "Sâu đục quả bông",
    "Spodoptera frugiperda": "Sâu keo mùa thu",
    "Agrotis ipsilon": "Sâu xám đen",
}

def get_vietnamese_name(scientific_name: str) -> str:
    """
    Get Vietnamese common name for a pest species.
    Returns Vietnamese name if available, otherwise returns scientific name.
    """
    return PEST_VIETNAMESE_NAMES.get(scientific_name, scientific_name)

def get_display_name(scientific_name: str, include_scientific: bool = True) -> str:
    """
    Get display name for a pest species.
    
    Args:
        scientific_name: Scientific name of the pest
        include_scientific: If True, include scientific name in parentheses
    
    Returns:
        Display name (e.g., "Rầy nâu (Nilaparvata lugens)" or just "Rầy nâu")
    """
    vietnamese_name = get_vietnamese_name(scientific_name)
    
    if include_scientific and vietnamese_name != scientific_name:
        return f"{vietnamese_name} ({scientific_name})"
    else:
        return vietnamese_name
