import 'package:flutter/material.dart';
import '../services/location_services.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String? initialValue;
  final String labelText;
  final String hintText;
  final void Function(String) onLocationSelected;
  final String? Function(String?)? validator;

  const LocationAutocompleteField({
    super.key,
    this.initialValue,
    this.labelText = 'Location',
    this.hintText = 'Enter your city or location',
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  late TextEditingController _controller;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      final suggestions = await LocationService.searchCities(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectLocation(LocationSuggestion suggestion) {
    _controller.text = suggestion.displayName;
    widget.onLocationSelected(suggestion.displayName);
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          validator: widget.validator,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(Icons.location_on, color: theme.colorScheme.primary),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            labelStyle: TextStyle(
              fontSize: 16, 
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)
            ),
            hintStyle: TextStyle(
              fontSize: 14, 
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          ),
          onChanged: (value) {
            widget.onLocationSelected(value);
            _searchLocations(value);
          },
          onTap: () {
            if (_controller.text.isNotEmpty) {
              _searchLocations(_controller.text);
            }
          },
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_city,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  title: Text(
                    suggestion.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    suggestion.adminName != null && suggestion.adminName!.isNotEmpty
                        ? '${suggestion.adminName}, ${suggestion.country}'
                        : suggestion.country,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _selectLocation(suggestion),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                );
              },
            ),
          ),
        // Invisible tap target to hide suggestions
        if (_showSuggestions)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideSuggestions,
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }
}