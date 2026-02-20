import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:jeeva_fit_ai/constants/app_constants.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';
import 'package:jeeva_fit_ai/widgets/onboarding_widgets.dart';

class PersonalInfoScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const PersonalInfoScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String? _selectedGender;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.fullName);
    _ageController = TextEditingController(text: widget.userProfile.age);
    _heightController = TextEditingController(text: widget.userProfile.heightCm);
    _weightController = TextEditingController(text: widget.userProfile.weightKg);
    _selectedGender = widget.userProfile.gender;
    
    // Check if there's a valid progressPhotoUrl and it's not the placeholder
    if (widget.userProfile.progressPhotoUrl != null && 
        !widget.userProfile.progressPhotoUrl!.contains('default_avatar')) {
      _selectedImage = File(widget.userProfile.progressPhotoUrl!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  // Save profile data on change
  void saveData() {
    final updatedProfile = widget.userProfile.copyWith(
      fullName: _nameController.text,
      age: _ageController.text,
      heightCm: _heightController.text,
      weightKg: _weightController.text,
      gender: _selectedGender,
      // Store the local path temporarily for display in the UI
      progressPhotoUrl: _selectedImage?.path,
    );
    widget.onProfileUpdated(updatedProfile);
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Store the image in the UserProvider for later upload
      Provider.of<UserProvider>(context, listen: false)
        .setProfileImage(_selectedImage);
      
      // Save the local path for now
      saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Your Personal Information',
            subtitle: 'Let\'s start with the basics to customize your experience',
          ),
          
          // Profile image with picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _selectedImage != null 
                        ? FileImage(_selectedImage!) 
                        : null,
                    child: _selectedImage == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Name
          LabeledTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            onChanged: (_) => saveData(),
            animationIndex: 1,
          ),
          
          // Age
          LabeledTextField(
            label: 'Age',
            hint: 'Enter your age',
            controller: _ageController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.calendar_today,
            onChanged: (_) => saveData(),
            animationIndex: 2,
          ),
          
          // Gender selection
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.genderOptions.map((gender) {
              final isSelected = _selectedGender == gender;
              return OptionCard(
                title: gender,
                icon: _getGenderIcon(gender),
                isSelected: isSelected,
                animationIndex: AppConstants.genderOptions.indexOf(gender) + 3,
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                  saveData();
                },
              );
            }).toList(),
          ),
          
          // Height
          LabeledTextField(
            label: 'Height (cm)',
            hint: 'Enter your height in centimeters',
            controller: _heightController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.height,
            onChanged: (_) => saveData(),
            animationIndex: 7,
          ),
          
          // Weight
          LabeledTextField(
            label: 'Weight (kg)',
            hint: 'Enter your weight in kilograms',
            controller: _weightController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.monitor_weight_outlined,
            onChanged: (_) => saveData(),
            animationIndex: 8,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person;
    }
  }
} 