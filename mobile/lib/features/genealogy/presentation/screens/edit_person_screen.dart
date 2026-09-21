// lib/features/genealogy/presentation/screens/edit_person_screen.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/direct_upload.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';

/// Modification des informations d'un membre. Retourne le membre mis à jour.
class EditPersonScreen extends StatefulWidget {
  final PersonModel person;
  const EditPersonScreen({super.key, required this.person});

  @override
  State<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends State<EditPersonScreen> {
  final _repository = GenealogyRepository();
  final _picker = ImagePicker();

  late final _nomCtrl = TextEditingController(text: widget.person.nom);
  late final _prenomCtrl = TextEditingController(text: widget.person.prenom ?? '');
  late final _lieuCtrl = TextEditingController(text: widget.person.lieuNaissance ?? '');
  late final _villageCtrl = TextEditingController(text: widget.person.villageOrigine ?? '');
  late final _nationaliteCtrl = TextEditingController(text: widget.person.nationalite ?? '');
  late final _professionCtrl = TextEditingController(text: widget.person.profession ?? '');
  late final _pereCtrl = TextEditingController(text: widget.person.nomPereTexte ?? '');
  late final _mereCtrl = TextEditingController(text: widget.person.nomMereTexte ?? '');
  late final _notesCtrl = TextEditingController(text: widget.person.notes ?? '');

  late String? _sexe = widget.person.sexe == 'INCONNU' ? null : widget.person.sexe;
  late DateTime? _naissance = _parse(widget.person.dateNaissance);
  late DateTime? _deces = _parse(widget.person.dateDeces);
  late bool _vivant = widget.person.vivant;

  Uint8List? _newPhoto;
  String? _newPhotoName;
  bool _removePhoto = false;
  bool _saving = false;
  String? _error;

  static DateTime? _parse(String? iso) =>
      iso == null || iso.length < 10 ? null : DateTime.tryParse(iso.substring(0, 10));

  static String _iso(DateTime d) => d.toIso8601String().split('T').first;

  static String _fr(DateTime? d) => d == null
      ? 'JJ / MM / AAAA'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void dispose() {
    for (final c in [
      _nomCtrl, _prenomCtrl, _lieuCtrl, _villageCtrl, _nationaliteCtrl,
      _professionCtrl, _pereCtrl, _mereCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newPhoto = bytes;
      _newPhotoName = file.name;
      _removePhoto = false;
    });
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime(1980),
        firstDate: DateTime(1800),
        lastDate: DateTime.now(),
      );

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est obligatoire.');
      return;
    }
    if (_naissance != null && _deces != null && _deces!.isBefore(_naissance!)) {
      setState(() => _error = 'La date de décès ne peut pas précéder la naissance.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      String? uploadedUrl;
      if (_newPhoto != null) {
        uploadedUrl = await uploadDirect(_newPhoto!, _newPhotoName ?? 'photo.jpg', 'person_photos');
      }

      final payload = <String, dynamic>{
        'nom': _nomCtrl.text.trim(),
        'prenom': _nullIfEmpty(_prenomCtrl.text),
        if (_sexe != null) 'sexe': _sexe,
        'date_naissance': _naissance == null ? null : _iso(_naissance!),
        'date_deces': (!_vivant && _deces != null) ? _iso(_deces!) : null,
        'vivant': _vivant,
        'lieu_naissance': _nullIfEmpty(_lieuCtrl.text),
        'village_origine': _nullIfEmpty(_villageCtrl.text),
        'nationalite': _nullIfEmpty(_nationaliteCtrl.text),
        'profession': _nullIfEmpty(_professionCtrl.text),
        'nom_pere_texte': _nullIfEmpty(_pereCtrl.text),
        'nom_mere_texte': _nullIfEmpty(_mereCtrl.text),
        'notes': _nullIfEmpty(_notesCtrl.text),
        if (uploadedUrl != null) 'photo': uploadedUrl,
        if (_removePhoto) 'photo': null,
      };

      var updated = await _repository.updatePerson(widget.person.id, payload);

      // Dev local (Cloudinary non configuré) : envoi de la photo via le backend.
      if (_newPhoto != null && uploadedUrl == null) {
        updated = await _repository.uploadPersonPhoto(
            widget.person.id, _newPhoto!, _newPhotoName ?? 'photo.jpg');
      }
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged,
      {bool clearable = true}) {
    return InkWell(
      onTap: () async {
        final picked = await _pickDate(value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: clearable && value != null
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => onChanged(null))
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(_fr(value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.person;
    final existingPhoto = (!_removePhoto && current.photo != null)
        ? resolveMediaUrl('person_photos', current.photo!)
        : null;
    final initial = _nomCtrl.text.trim().isNotEmpty ? _nomCtrl.text.trim()[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le membre')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.grisClair,
                        backgroundImage: _newPhoto != null
                            ? MemoryImage(_newPhoto!)
                            : (existingPhoto != null ? NetworkImage(existingPhoto) as ImageProvider : null),
                        child: (_newPhoto == null && existingPhoto == null)
                            ? Text(initial,
                                style: const TextStyle(fontSize: 30, color: AppColors.gris, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(color: AppColors.or, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppColors.noir),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (_newPhoto != null || existingPhoto != null) ? 'Changer la photo' : 'Ajouter une photo',
                  style: const TextStyle(fontSize: 12, color: AppColors.gris),
                ),
                if (_newPhoto != null || existingPhoto != null)
                  TextButton(
                    onPressed: () => setState(() { _newPhoto = null; _newPhotoName = null; _removePhoto = true; }),
                    child: const Text('Retirer la photo',
                        style: TextStyle(fontSize: 12, color: AppColors.erreur)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            AppBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          AppTextField(label: 'Nom *', controller: _nomCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Prénom(s)', controller: _prenomCtrl),
          const SizedBox(height: 14),
          const Text('Sexe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'M', label: Text('Masculin')),
              ButtonSegment(value: 'F', label: Text('Féminin')),
            ],
            selected: _sexe == null ? <String>{} : {_sexe!},
            onSelectionChanged: (v) => setState(() => _sexe = v.isEmpty ? null : v.first),
          ),
          const SizedBox(height: 16),
          _dateField('Date de naissance', _naissance, (d) => setState(() => _naissance = d)),
          CheckboxListTile(
            value: _vivant,
            onChanged: (v) => setState(() => _vivant = v ?? true),
            title: const Text('Cette personne est vivante'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_vivant) ...[
            _dateField('Date de décès', _deces, (d) => setState(() => _deces = d)),
            const SizedBox(height: 12),
          ],
          AppTextField(label: 'Lieu de naissance', controller: _lieuCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Village / localité d\'origine', controller: _villageCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Nationalité', controller: _nationaliteCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Profession', controller: _professionCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Nom du père (si non présent dans l\'arbre)', controller: _pereCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Nom de la mère (si non présente dans l\'arbre)', controller: _mereCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Notes', controller: _notesCtrl, maxLines: 4),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Enregistrer les modifications',
            isLoading: _saving,
            backgroundColor: AppColors.vertForet,
            onPressed: _saving ? () {} : _save,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
