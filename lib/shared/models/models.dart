/// Shared data models for the Zanny Collection app
library;

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
      category: (json['category'] as String?) ?? (json['category_slug'] as String?) ?? '',
      isNew: json['is_new'] as bool? ?? false,
      isSale: json['is_sale'] as bool? ?? false,
      stock: json['stock'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'images': images,
      'colors': colors,
      'sizes': sizes,
      'category': category,
      'is_new': isNew,
      'is_sale': isSale,
      'stock': stock,
    };
  }

  static List<Product> get defaultMockProducts => const [
    Product(
      id: 'new_1',
      name: 'Oversized ZC Heavyweight Hoodie',
      subtitle: 'New Season',
      description: 'The ultimate streetwear statement. Crafted from 450GSM organic loopback cotton, this hoodie features dropped shoulders, double-lined hood without drawcords, and custom silicone-injected chest branding.',
      price: 3800,
      originalPrice: 4500,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_black_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_grey_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/styles/style_2_1.jpg'
      ],
      colors: ['Charcoal Black', 'Heather Grey', 'Olive Green'],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      category: 'hoodies',
      isNew: true,
      isSale: true,
    ),
    Product(
      id: 'new_2',
      name: 'ZC Vibe Box Graphic Tee',
      subtitle: 'New Season',
      description: 'Ultra-premium vintage wash jersey tee. 240GSM combed cotton, oversized retro silhouette with high collar rib. High-density puff print graphic at the front.',
      price: 1800,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_black_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_white_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/styles/style_2_2.jpg'
      ],
      colors: ['Vintage Black', 'Off-White', 'Muted Red'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shirts-tees',
      isNew: true,
    ),
    Product(
      id: 'new_3',
      name: 'ZC Utility Cargo Sweatpants',
      subtitle: 'New Season',
      description: 'Fleece-lined utility joggers with signature double-pockets at sides. Elastic waistband and cuffs with internal drawstring. Minimalist brand embroidery.',
      price: 2900,
      originalPrice: 3200,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_black_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_grey_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/new_arrivals.jpg'
      ],
      colors: ['Black', 'Sand', 'Stone Grey'],
      sizes: ['M', 'L', 'XL'],
      category: 'shorts-sweatpants',
      isNew: true,
      isSale: true,
    ),
    Product(
      id: 'tee_1',
      name: 'ZC Signature Minimalist Tee',
      subtitle: 'Essential Collection',
      description: 'Our classic everyday heavyweight tee. Features a premium boxy fit, tight crewneck collar, and subtle tonal branding.',
      price: 1500,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_white_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_black_1.jpg'
      ],
      colors: ['Black', 'White', 'Beige', 'Navy'],
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      category: 'shirts-tees',
    ),
    Product(
      id: 'tee_2',
      name: 'ZC Oversized Waffle Knit Shirt',
      subtitle: 'Summer Drops',
      description: 'Relaxed button-up shirt in premium waffle textured cotton. Perfect lightweight outer layer for warm afternoons.',
      price: 2400,
      originalPrice: 2800,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_red_2.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/tee_black_1.jpg'
      ],
      colors: ['Cream', 'Olive', 'Charcoal'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shirts-tees',
      isSale: true,
    ),
    Product(
      id: 'hoodie_1',
      name: 'ZC Street Culture Pullover',
      subtitle: 'Streetwear Essentials',
      description: 'Heavy fleece core hoodie with kangaroo pocket and embroidered street crest. Relaxed boxy fit.',
      price: 3200,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_grey_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_black_1.jpg'
      ],
      colors: ['Core Black', 'Cream White', 'Mocha'],
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      category: 'hoodies',
    ),
    Product(
      id: 'hoodie_2',
      name: 'ZC Essential Zip-Up Hoodie',
      subtitle: 'Streetwear Essentials',
      description: 'Ultra-soft fleece lined full zip hoodie. Heavyweight cotton build with polished metal zippers, ribbed cuffs, and minimal sleeve branding.',
      price: 3400,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_grey_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/hoodie_black_1.jpg'
      ],
      colors: ['Black', 'Off-White'],
      sizes: ['M', 'L', 'XL'],
      category: 'hoodies',
    ),
    Product(
      id: 'sweater_1',
      name: 'ZC Cable-Knit Chunky Sweater',
      subtitle: 'Premium Knits',
      description: 'Thick and warm cable-knit sweater made from premium wool blend. Clean minimalist ribbed hem.',
      price: 2800,
      originalPrice: 3500,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/sweater_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/sweater_2.jpg'
      ],
      colors: ['Off-White', 'Sage Green', 'Navy Blue'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'sweaters',
      isSale: true,
    ),
    Product(
      id: 'sweater_2',
      name: 'ZC Knitted Crewneck Sweatshirt',
      subtitle: 'Premium Knits',
      description: 'A cozy cotton-acrylic blend sweater featuring a relaxed crewneck cut and custom vertical rib patterns.',
      price: 2600,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/sweater_2.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/sweater_1.jpg'
      ],
      colors: ['Navy Blue', 'Olive Green'],
      sizes: ['S', 'M', 'L'],
      category: 'sweaters',
    ),
    Product(
      id: 'short_1',
      name: 'ZC Fleece Comfort Shorts',
      subtitle: 'Casual Lounge',
      description: 'Heavy fleece shorts with zipper pockets and embroidered Z logo. Designed for everyday premium comfort.',
      price: 1800,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_grey_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_black_1.jpg'
      ],
      colors: ['Black', 'Heather Grey', 'Sage'],
      sizes: ['S', 'M', 'L', 'XL'],
      category: 'shorts-sweatpants',
    ),
    Product(
      id: 'pants_1',
      name: 'ZC Tech-Fleece Track Pants',
      subtitle: 'Casual Lounge',
      description: 'Premium tech fleece material joggers. Modern tapered athletic fit with side seam zip pockets and drawstring cuffs.',
      price: 2700,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_black_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/pants_grey_1.jpg'
      ],
      colors: ['Black', 'Charcoal'],
      sizes: ['M', 'L', 'XL'],
      category: 'shorts-sweatpants',
    ),
    Product(
      id: 'shoe_1',
      name: 'ZC Urban Runner Sneaker',
      subtitle: 'Street Footwear',
      description: 'Premium calfskin leather sneakers with custom chunky lightweight sole and orthotic memory insole.',
      price: 4800,
      originalPrice: 6000,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/shoe_red_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/shoe_blue_1.jpg'
      ],
      colors: ['Triple Black', 'Mono White', 'Vintage Cream'],
      sizes: ['40', '41', '42', '43', '44'],
      category: 'shoes',
      isSale: true,
    ),
    Product(
      id: 'shoe_2',
      name: 'ZC Retro Court Sneaker',
      subtitle: 'Street Footwear',
      description: 'Vintage-inspired basketball court sneakers crafted from full-grain leather, featuring a padded tongue and dynamic color blocks.',
      price: 5200,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/shoe_blue_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/shoe_red_1.jpg'
      ],
      colors: ['White/Green', 'White/Black'],
      sizes: ['41', '42', '43'],
      category: 'shoes',
    ),
    Product(
      id: 'inner_1',
      name: 'ZC Bamboo Boxer Briefs (3-Pack)',
      subtitle: 'Essentials',
      description: 'Super-soft and breathable bamboo fiber boxer briefs. Seamless design with anti-roll waistband.',
      price: 1500,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/inner_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/inner_1.jpg'
      ],
      colors: ['Multi-pack (Black/Grey/Navy)'],
      sizes: ['M', 'L', 'XL'],
      category: 'innerwear',
    ),
    Product(
      id: 'inner_2',
      name: 'ZC Premium Lounge Robe',
      subtitle: 'Essentials',
      description: 'Unisex luxury waffle robe crafted from fine organic cotton. Breathable, absorbent, and designed for ultimate relaxation.',
      price: 3500,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/inner_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/inner_1.jpg'
      ],
      colors: ['Navy', 'Charcoal'],
      sizes: ['S/M', 'L/XL'],
      category: 'innerwear',
    ),
    Product(
      id: 'acc_1',
      name: 'ZC Signature Trucker Cap',
      subtitle: 'Headwear',
      description: 'Curved visor trucker hat with high-density foam front panel, mesh back, and snapback adjustment.',
      price: 1200,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_1.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_3.jpg'
      ],
      colors: ['Black/White', 'All Black', 'Brown/Beige'],
      sizes: ['One Size'],
      category: 'accessories',
    ),
    Product(
      id: 'acc_2',
      name: 'ZC Classic Leather Cardholder',
      subtitle: 'Leathergoods',
      description: 'Handcrafted genuine leather card sleeve. Features 4 card slots and a central cash compartment. High-contrast edge stitching.',
      price: 1600,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_2.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_1.jpg'
      ],
      colors: ['Black Leather', 'Tan Leather'],
      sizes: ['One Size'],
      category: 'accessories',
    ),
    Product(
      id: 'acc_3',
      name: 'ZC Street Knit Beanie',
      subtitle: 'Headwear',
      description: 'Classic ribbed knit watch cap. Super stretchy acrylic yarn with woven branded label at the fold.',
      price: 950,
      originalPrice: null,
      images: [
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_3.jpg',
        'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/products/acc_1.jpg'
      ],
      colors: ['Charcoal', 'Mustard', 'Orange'],
      sizes: ['One Size'],
      category: 'accessories',
    ),
  ];
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
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/new_arrivals.jpg',
    ),
    const ProductCategory(
      slug: 'shirts-tees',
      name: 'Shirts & T-Shirts',
      description: 'Premium cuts for the modern wardrobe',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/shirts_tees.jpg',
    ),
    const ProductCategory(
      slug: 'hoodies',
      name: 'Hoodies',
      description: 'Cozy and street-ready',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/hoodies.jpg',
    ),
    const ProductCategory(
      slug: 'sweaters',
      name: 'Sweaters',
      description: 'Elevated comfort',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/sweaters.jpg',
    ),
    const ProductCategory(
      slug: 'shorts-sweatpants',
      name: 'Shorts & Sweatpants',
      description: 'Comfort meets culture',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/shorts_pants.jpg',
    ),
    const ProductCategory(
      slug: 'shoes',
      name: 'Shoes',
      description: 'Step up your game',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/shoes.jpg',
    ),
    const ProductCategory(
      slug: 'innerwear',
      name: 'Innerwear',
      description: 'The foundation of style',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/innerwear.jpg',
    ),
    const ProductCategory(
      slug: 'accessories',
      name: 'Accessories',
      description: 'The finishing touch',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/accessories.jpg',
    ),
    const ProductCategory(
      slug: 'sale',
      name: 'Sale',
      description: 'Premium at a lower price',
      imageUrl: 'https://pub-0a4117480fe8436ca1a1255ce208d231.r2.dev/categories/sale.jpg',
    ),
  ];
}

class CartItem {
  final Product product;
  final String selectedColor;
  final String selectedSize;
  final int quantity;
  final bool isConfirmed;

  const CartItem({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    this.quantity = 1,
    this.isConfirmed = true,
  });

  double get subtotal => product.price * quantity;

  String get key => '${product.id}_${selectedColor}_$selectedSize';

  CartItem copyWith({
    Product? product,
    String? selectedColor,
    String? selectedSize,
    int? quantity,
    bool? isConfirmed,
  }) {
    return CartItem(
      product: product ?? this.product,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      selectedColor: json['selected_color'] as String? ?? '',
      selectedSize: json['selected_size'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      isConfirmed: json['is_confirmed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'selected_color': selectedColor,
      'selected_size': selectedSize,
      'quantity': quantity,
      'is_confirmed': isConfirmed,
    };
  }
}

class Address {
  final String id;
  final String recipientName;
  final String phone;
  final String streetAddress;
  final String city;
  final String postalCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.streetAddress,
    required this.city,
    required this.postalCode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      recipientName: json['recipient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      streetAddress: json['street_address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'phone': phone,
      'street_address': streetAddress,
      'city': city,
      'postal_code': postalCode,
      'is_default': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? streetAddress,
    String? city,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'delivered'
  final DateTime createdAt;
  final String deliveryAddress;
  final String recipientName;
  final String recipientPhone;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      items: (json['items'] as List)
          .map((i) => CartItem(
                product: Product.fromJson(Map<String, dynamic>.from(i['product'])),
                selectedColor: i['selected_color'] as String? ?? '',
                selectedSize: i['selected_size'] as String? ?? '',
                quantity: i['quantity'] as int? ?? 1,
                isConfirmed: i['is_confirmed'] as bool? ?? true,
              ))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveryAddress: json['delivery_address'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items
          .map((i) => {
                'product': i.product.toJson(),
                'selected_color': i.selectedColor,
                'selected_size': i.selectedSize,
                'quantity': i.quantity,
                'is_confirmed': i.isConfirmed,
              })
          .toList(),
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'delivery_address': deliveryAddress,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
    };
  }
}

