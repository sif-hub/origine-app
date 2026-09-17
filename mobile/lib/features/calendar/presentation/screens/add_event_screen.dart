// lib/features/calendar/presentation/screens/add_event_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/event_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/events_repository.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime initialDate;
  const AddEventScreen({super.key, required this.initialDate});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _repository = EventsRepository();
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _personneCtrl = TextEditingController();
  String _typeEvenement = 'ANNIVERSAIRE';
  late DateTime _date = widget.initialDate;
  TimeOfDay? _heure;
  bool _saving = false;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _heure ?? TimeOfDay.now());
    if (picked != null) setState(() => _heure = picked);
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom de l\'événement est obligatoire.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final draft = FamilyEventModel(
        id: 0,
        nom: _nomCtrl.text.trim(),
        typeEvenement: _typeEvenement,
        dateEvenement: _date,
        heure: _heure != null
            ? '${_heure!.hour.toString().padLeft(2, '0')}:${_heure!.minute.toString().padLeft(2, '0')}'
            : null,
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        personneConcernee: _personneCtrl.text.trim().isEmpty ? null : _personneCtrl.text.trim(),
      );
      await _repository.createEvent(draft);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _personneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un événement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              AppBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'Nom de l\'événement *', controller: _nomCtrl),
            const SizedBox(height: 14),
            const Text('Type d\'événement', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _typeEvenement,
              items: kEventTypeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _typeEvenement = v ?? 'AUTRE'),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickTime,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Heure (optionnel)'),
                child: Text(_heure == null ? '--:--' : _heure!.format(context)),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Personne concernée (optionnel)', controller: _personneCtrl),
            const SizedBox(height: 14),
            AppTextField(label: 'Description (optionnel)', controller: _descriptionCtrl, maxLines: 4),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Ajouter',
              isLoading: _saving,
              backgroundColor: AppColors.vertForet,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
