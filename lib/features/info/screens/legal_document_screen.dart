import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

enum LegalDocumentType { privacyPolicy, termsOfService, cookiePolicy }

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _getContent(textTheme),
        ),
      ),
    );
  }

  List<Widget> _getContent(TextTheme textTheme) {
    switch (type) {
      case LegalDocumentType.privacyPolicy:
        return _buildPrivacyPolicy(textTheme);
      case LegalDocumentType.termsOfService:
        return _buildTermsOfService(textTheme);
      case LegalDocumentType.cookiePolicy:
        return _buildCookiePolicy(textTheme);
    }
  }

  // ── Terms of Service ────────────────────────────────────────────────────────
  List<Widget> _buildTermsOfService(TextTheme textTheme) {
    return [
      _h1(textTheme, 'Terms of Service'),
      _metaText(textTheme, 'Last Updated: June 2026'),
      _p(textTheme, 'Welcome to Zanny Collection. These Terms of Service ("Terms") govern your access to and use of our mobile application and services. By downloading, accessing, or using the Zanny Collection app, you agree to be bound by these Terms. If you do not agree, please do not use our services.'),
      
      _h2(textTheme, '1. User Accounts & Registration'),
      _p(textTheme, 'To place orders or save items to your wishlist, you must create an account. You agree to provide accurate, current, and complete information during registration. You are solely responsible for maintaining the confidentiality of your account credentials (email and password) and for all activities that occur under your account.'),
      
      _h2(textTheme, '2. Products, Pricing & Availability'),
      _p(textTheme, 'All items displayed in the app are subject to availability. Zanny Collection reserves the right to modify prices, descriptions, and stock counts without prior notice. While we make every effort to display product colors and designs accurately, your device screen representation may vary slightly.'),
      
      _h2(textTheme, '3. Checkout & Payment Options'),
      _p(textTheme, 'We accept standard secure payments (such as MPESA and cards). All payments must be cleared before dispatching your order. By placing an order, you represent that you are authorized to use the designated payment method.'),
      
      _h2(textTheme, '4. Shipping Fees & Delivery'),
      _p(textTheme, 'We ship products across Kenya. A standard delivery fee of KSH 250 is applied to all domestic orders unless specified otherwise. Delivery timelines are estimates and may vary due to location, traffic, or carrier delays.'),
      
      _h2(textTheme, '5. Returns & Exchange Policy'),
      _p(textTheme, 'We accept returns and exchange requests within 7 days from the delivery date. Items must be unworn, unwashed, and returned in their original packaging with all product tags intact. Sale/discounted items are not eligible for returns or refunds unless they arrive damaged.'),
      
      _h2(textTheme, '6. Governing Law'),
      _p(textTheme, 'These Terms and your use of our app shall be governed by and construed in accordance with the laws of Kenya, without regard to its conflict of law principles.'),
    ];
  }

  // ── Privacy Policy ──────────────────────────────────────────────────────────
  List<Widget> _buildPrivacyPolicy(TextTheme textTheme) {
    return [
      _h1(textTheme, 'Privacy Policy'),
      _metaText(textTheme, 'Last Updated: June 2026'),
      _p(textTheme, 'At Zanny Collection, we value your privacy and are committed to protecting your personal data. This Privacy Policy describes how we collect, use, and protect your information when you use our mobile application.'),
      
      _h2(textTheme, '1. Information We Collect'),
      _p(textTheme, 'We collect personal information that you provide directly to us when creating an account, editing your profile, or making a purchase. This includes:'),
      _bullet(textTheme, 'Full Name and Contact details (email address, phone number)'),
      _bullet(textTheme, 'Delivery and Shipping Addresses'),
      _bullet(textTheme, 'Device metadata and active FCM tokens (for push notifications)'),
      
      _h2(textTheme, '2. How We Use Your Data'),
      _p(textTheme, 'Your personal data is used solely to enhance your streetwear shopping experience, including:'),
      _bullet(textTheme, 'Processing, shipping, and tracking your orders'),
      _bullet(textTheme, 'Saving your favorite items to your wishlist'),
      _bullet(textTheme, 'Sending you status notifications and promotional updates'),
      _bullet(textTheme, 'Managing your authenticated Supabase user session securely'),
      
      _h2(textTheme, '3. Payment & Security'),
      _p(textTheme, 'We do not store or process your raw payment credentials on our database servers. All transactions are securely handled by integrated authorized third-party payment gateways. Our database uses secure SSL encryption and row-level security (RLS) policies to prevent unauthorized data access.'),
      
      _h2(textTheme, '4. Data Retention'),
      _p(textTheme, 'We store your personal profile and order history as long as your account remains active. You can request the deletion of your account and related data at any time by contacting our support team via the Profile screen.'),
    ];
  }

  // ── Cookie Policy ───────────────────────────────────────────────────────────
  List<Widget> _buildCookiePolicy(TextTheme textTheme) {
    return [
      _h1(textTheme, 'Cookie Policy'),
      _metaText(textTheme, 'Last Updated: June 2026'),
      _p(textTheme, 'Zanny Collection uses standard local storage mechanisms (which behave like cookies) inside our mobile application to provide a functional and premium user experience.'),
      
      _h2(textTheme, '1. What Are Cookies in a Mobile App?'),
      _p(textTheme, 'In mobile applications, we use secure local key-value stores (such as SharedPreferences and Hive) to store preferences locally on your device, serving the same purpose as browser cookies.'),
      
      _h2(textTheme, '2. Why We Use Local Storage'),
      _p(textTheme, 'We store essential local data to facilitate features such as:'),
      _bullet(textTheme, 'Session persistence (keeping you securely logged in between app launches)'),
      _bullet(textTheme, 'Theme preferences (saving whether you selected Light, Dark, or System mode)'),
      _bullet(textTheme, 'Offline caching of your local cart and wishlist items for speed'),
      
      _h2(textTheme, '3. Control and Opt-Out'),
      _p(textTheme, 'Local session and settings data can be cleared at any time by choosing "Sign Out" or clearing the application data cache in your Android system settings. Disabling local storage entirely will prevent the app from keeping you logged in or persisting your cart.'),
    ];
  }

  // Helper widgets for premium formatting
  Widget _h1(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _metaText(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _h2(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _p(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.6,
          color: textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _bullet(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: textTheme.bodyMedium?.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
