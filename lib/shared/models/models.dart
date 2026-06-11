/// Shared data models for the Zanny Collection app

class Product {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final double price;
  final double? originalPrice;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final String category;
  final bool isNew;
  final bool isSale;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    required this.colors,
    required this.sizes,
    required this.category,
    this.isNew = false,
    this.isSale = false,
    this.stock = 10,
  });

  bool get isOnSale => originalPrice != null && originalPrice! > price;
  int get discountPercent => isOnSale
      ? ((1 - price / originalPrice!) * 100).round()
      : 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      images: List<String>.from(json['images'] as List? ?? []),
      colors: List<String>.from(json['colors'] as List? ?? []),
      sizes: List<String>.from(json['sizes'] as List? ?? []),
      category: json['category'] as String? ?? '',
      isNew: json['is_new'] as bool? ?? false,
      isSale: json['is_sale'] as bool? ?? false,
      stock: json['stock'] as int? ?? 10,
    );
  }
}

class ProductCategory {
  final String slug;
  final String name;
  final String description;
  final String imageUrl;
  final int productCount;

  const ProductCategory({
    required this.slug,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.productCount = 0,
  });

  static List<ProductCategory> get all => [
    const ProductCategory(
      slug: 'new-arrivals',
      name: 'New Arrivals',
      description: 'Fresh drops straight from the streets',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/new-arrivals.jpg',
    ),
    const ProductCategory(
      slug: 'shirts-t-shirts',
      name: 'Shirts & T-Shirts',
      description: 'Premium cuts for the modern wardrobe',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/shirts.jpg',
    ),
    const ProductCategory(
      slug: 'hoodies',
      name: 'Hoodies',
      description: 'Cozy and street-ready',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/hoodies.jpg',
    ),
    const ProductCategory(
      slug: 'sweaters',
      name: 'Sweaters',
      description: 'Elevated comfort',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/sweaters.jpg',
    ),
    const ProductCategory(
      slug: 'shorts-sweatpants',
      name: 'Shorts & Sweatpants',
      description: 'Comfort meets culture',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/shorts.jpg',
    ),
    const ProductCategory(
      slug: 'shoes',
      name: 'Shoes',
      description: 'Step up your game',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/shoes.jpg',
    ),
    const ProductCategory(
      slug: 'innerwear',
      name: 'Innerwear',
      description: 'The foundation of style',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/innerwear.jpg',
    ),
    const ProductCategory(
      slug: 'accessories',
      name: 'Accessories',
      description: 'The finishing touch',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/accessories.jpg',
    ),
    const ProductCategory(
      slug: 'sale',
      name: 'Sale',
      description: 'Premium at a lower price',
      imageUrl: 'https://zannycollection.com/cdn/shop/collections/sale.jpg',
    ),
  ];
}

class CartItem {
  final Product product;
  final String selectedColor;
  final String selectedSize;
  final int quantity;

  const CartItem({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;

  String get key => '${product.id}_${selectedColor}_$selectedSize';

  CartItem copyWith({
    Product? product,
    String? selectedColor,
    String? selectedSize,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
    );
  }
}
