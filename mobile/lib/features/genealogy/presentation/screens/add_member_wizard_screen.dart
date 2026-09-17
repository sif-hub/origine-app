// lib/features/genealogy/presentation/screens/add_member_wizard_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/person_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/genealogy_repository.dart';
import '../../domain/add_member_bloc.dart';
import 'member_verification_screen.dart';

const _relationLabels = {
  'PERE': 'Père',
  'MERE': 'Mère',
  'CONJOINT': 'Conjoint(e)',
  'ENFANT': 'Enfant',
  'FRERE_SOEUR': 'Frère / Sœur',
};

const _documentTypes = {
  'ACTE_NAISSANCE': 'Acte de naissance',
  'ACTE_MARIAGE': 'Acte de mariage',
  'ACTE_DECES': 'Acte de décès',
  'AUTRE': 'Autre document',
};

class AddMemberWizardScreen extends StatelessWidget {
  final int familyId;
  final List<PersonModel> existingPersons;
  final PersonModel? initialReferencePerson;
  final String? initialRelationType;

  const AddMemberWizardScreen({
    super.key,
    required this.familyId,
    required this.existingPersons,
    this.initialReferencePerson,
    this.initialRelationType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddMemberBloc(GenealogyRepository()),
      child: _AddMemberWizardView(
        familyId: familyId,
        existingPersons: existingPersons,
        initialReferencePerson: initialReferencePerson,
        initialRelationType: initialRelationType,
      ),
    );
  }
}

class _AddMemberWizardView extends StatefulWidget {
  final int familyId;
  final List<PersonModel> existingPersons;
  final PersonModel? initialReferencePerson;
  final String? initialRelationType;

  const _AddMemberWizardView({
    required this.familyId,
    required this.existingPersons,
    this.initialReferencePerson,
    this.initialRelationType,
  });

  @override
  State<_AddMemberWizardView> createState() => _AddMemberWizardViewState();
}

class _AddMemberWizardViewState extends State<_AddMemberWizardView> {
  final _pageController = PageController();
  int _step = 0;
  static const _stepCount = 5;

  // Étape 1
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  String _sexe = 'INCONNU';
  DateTime? _dateNaissance;
  bool _vivant = true;
  final _lieuNaissanceCtrl = TextEditingController();
  final _villageOrigineCtrl = TextEditingController();
  final _nationaliteCtrl = TextEditingController(text: 'Camerounais(e)');
  final _professionCtrl = TextEditingController();

  // Étape 2
  PersonModel? _referencePerson;
  String _relationType = 'AUCUN';
  final _nomPereCtrl = TextEditingController();
  final _nomMereCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Étape 3
  final List<DraftDocument> _documents = [];

  // Étape 4
  final List<DraftMemory> _memories = [];

  // Étape 5
  String _visibilite = 'PRIVE';
  bool _peutVoir = true;
  bool _peutModifier = false;
  bool _peutAjouterDocuments = false;
  bool _peutAjouterSouvenirs = true;
  bool _peutCommenter = true;

  @override
  void initState() {
    super.initState();
    _referencePerson = widget.initialReferencePerson ??
        (widget.existingPersons.isNotEmpty ? widget.existingPersons.first : null);
    if (widget.initialRelationType != null) _relationType = widget.initialRelationType!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _nomCtrl, _prenomCtrl, _lieuNaissanceCtrl, _villageOrigineCtrl,
      _nationaliteCtrl, _professionCtrl, _nomPereCtrl, _nomMereCtrl, _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canGoNext {
    if (_step == 0) return _nomCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    if (_step == _stepCount - 1) {
      _submit();
      return;
    }
    if (!_canGoNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire.')),
      );
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _previous() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(_step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _submit() {
    final draft = MemberDraft(
      familyId: widget.familyId,
      anchorPersonId: _referencePerson?.id,
      relationType: _referencePerson == null ? 'AUCUN' : _relationType,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim().isEmpty ? null : _prenomCtrl.text.trim(),
      sexe: _sexe,
      dateNaissance: _dateNaissance == null
          ? null
          : _dateNaissance!.toIso8601String().split('T').first,
      vivant: _vivant,
      lieuNaissance: _emptyToNull(_lieuNaissanceCtrl.text),
      villageOrigine: _emptyToNull(_villageOrigineCtrl.text),
      nationalite: _emptyToNull(_nationaliteCtrl.text),
      profession: _emptyToNull(_professionCtrl.text),
      nomPereTexte: _emptyToNull(_nomPereCtrl.text),
      nomMereTexte: _emptyToNull(_nomMereCtrl.text),
      notes: _emptyToNull(_notesCtrl.text),
      documents: _documents,
      memories: _memories,
      visibilite: _visibilite,
      peutVoir: _peutVoir,
      peutModifier: _peutModifier,
      peutAjouterDocuments: _peutAjouterDocuments,
      peutAjouterSouvenirs: _peutAjouterSouvenirs,
      peutCommenter: _peutCommenter,
    );
    context.read<AddMemberBloc>().add(SubmitMemberRequested(draft));
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddMemberBloc, AddMemberState>(
      listener: (context, state) {
        if (state is AddMemberSuccess) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => MemberVerificationScreen(person: state.person, draft: state.draft),
          ));
        } else if (state is AddMemberFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter un membre'),
          leading: BackButton(onPressed: _previous),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: WizardStepIndicator(
                stepCount: _stepCount,
                currentStep: _step,
                labels: const ['Infos', 'Relations', 'Documents', 'Souvenirs', 'Confidentialité'],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoStep(),
                  _buildRelationsStep(),
                  _buildDocumentsStep(),
                  _buildMemoriesStep(),
                  _buildPrivacyStep(),
                ],
              ),
            ),
            BlocBuilder<AddMemberBloc, AddMemberState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(16),
                child: AppPrimaryButton(
                  label: _step == _stepCount - 1 ? 'Enregistrer le membre' : 'Suivant',
                  isLoading: state is AddMemberSubmitting,
                  onPressed: _next,
                  backgroundColor: AppColors.vertForet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : INFORMATIONS ────────────────────────────────────────
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Informations personnelles',
            subtitle: 'Renseignez les informations de base du membre.',
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Nom *', controller: _nomCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Prénom(s)', controller: _prenomCtrl),
          const SizedBox(height: 12),
          const Text('Sexe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'M', label: Text('Masculin')),
              ButtonSegment(value: 'F', label: Text('Féminin')),
              ButtonSegment(value: 'INCONNU', label: Text('Autre')),
            ],
            selected: {_sexe},
            onSelectionChanged: (v) => setState(() => _sexe = v.first),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateNaissance ?? DateTime(1980),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateNaissance = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date de naissance'),
              child: Text(_dateNaissance == null
                  ? 'JJ / MM / AAAA'
                  : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}'),
            ),
          ),
          CheckboxListTile(
            value: _vivant,
            onChanged: (v) => setState(() => _vivant = v ?? true),
            title: const Text('Je suis une personne vivante'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          AppTextField(label: 'Lieu de naissance', controller: _lieuNaissanceCtrl),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Village / localité d\'origine', controller: _villageOrigineCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Nationalité', controller: _nationaliteCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Profession (facultatif)', controller: _professionCtrl),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 2 : RELATIONS ───────────────────────────────────────────
  Widget _buildRelationsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Liens familiaux',
            subtitle: 'Définissez la relation de ce membre avec les autres membres de l\'arbre.',
          ),
          const SizedBox(height: 16),
          if (widget.existingPersons.isEmpty)
            const AppBanner(
              message: 'Aucun autre membre dans cet arbre pour le moment : ce membre sera ajouté seul.',
              isError: false,
            )
          else ...[
            DropdownButtonFormField<PersonModel>(
              value: _referencePerson,
              decoration: const InputDecoration(labelText: 'Personne de référence dans l\'arbre'),
              items: widget.existingPersons
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.nomComplet)))
                  .toList(),
              onChanged: (p) => setState(() => _referencePerson = p),
            ),
            const SizedBox(height: 12),
            if (_referencePerson != null) ...[
              const Text('Ce membre est son/sa :',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relationLabels.entries.map((entry) {
                  final selected = _relationType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _relationType = entry.key),
                    selectedColor: AppColors.vertForet,
                    labelStyle: TextStyle(color: selected ? AppColors.blanc : AppColors.noir),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 20),
          AppTextField(label: 'Nom du père (si connu)', controller: _nomPereCtrl),
          const SizedBox(height: 12),
          AppTextField(label: 'Nom de la mère (si connue)', controller: _nomMereCtrl),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Notes',
            controller: _notesCtrl,
            maxLines: 3,
            hint: 'Ajoutez des informations complémentaires...',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 3 : DOCUMENTS ───────────────────────────────────────────
  Future<void> _pickDocument(String typeDocument) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      _documents.removeWhere((d) => d.typeDocument == typeDocument);
      _documents.add(DraftDocument(
        typeDocument: typeDocument,
        bytes: file!.bytes!,
        filename: file.name,
      ));
    });
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Documents',
            subtitle: 'Ajoutez les documents disponibles (tous facultatifs).',
          ),
          const SizedBox(height: 16),
          ..._documentTypes.entries.map((entry) {
            final existing = _documents.where((d) => d.typeDocument == entry.key).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.vertForet),
                  title: Text(entry.value),
                  subtitle: existing.isNotEmpty ? Text(existing.first.filename) : null,
                  trailing: existing.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.erreur),
                          onPressed: () => setState(() =>
                              _documents.removeWhere((d) => d.typeDocument == entry.key)),
                        )
                      : TextButton(
                          onPressed: () => _pickDocument(entry.key),
                          child: const Text('Ajouter'),
                        ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 4 : SOUVENIRS ───────────────────────────────────────────
  final _picker = ImagePicker();

  Future<void> _pickImageMemory() async {
    final files = await _picker.pickMultiImage();
    for (final f in files) {
      final bytes = await f.readAsBytes();
      setState(() => _memories.add(DraftMemory(type: 'PHOTO', bytes: bytes, filename: f.name)));
    }
  }

  Future<void> _pickAudioVideoMemory(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'VIDEO' ? FileType.video : FileType.audio,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _memories.add(DraftMemory(type: type, bytes: file!.bytes!, filename: file.name)));
  }

  Widget _buildMemoriesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Souvenirs et galerie',
            subtitle: 'Conservez les souvenirs qui racontent l\'histoire de ce membre.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImageMemory,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ajouter des photos'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickAudioVideoMemory('VIDEO'),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Ajouter une vidéo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickAudioVideoMemory('AUDIO'),
                icon: const Icon(Icons.mic_none_outlined),
                label: const Text('Ajouter un audio'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_memories.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _memories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final memory = _memories[i];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grisClair,
                        borderRadius: BorderRadius.circular(10),
                        image: memory.type == 'PHOTO'
                            ? DecorationImage(
                                image: MemoryImage(memory.bytes), fit: BoxFit.cover)
                            : null,
                      ),
                      child: memory.type != 'PHOTO'
                          ? Center(
                              child: Icon(
                                memory.type == 'VIDEO' ? Icons.videocam : Icons.audiotrack,
                                color: AppColors.vertForet,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _memories.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.erreur,
                          child: Icon(Icons.close, size: 14, color: AppColors.blanc),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 5 : CONFIDENTIALITÉ ──────────────────────────────────────
  Widget _buildPrivacyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Confidentialité et partage',
            subtitle: 'Choisissez qui peut voir ce membre et comment il peut être utilisé.',
          ),
          const SizedBox(height: 16),
          const Text('Visibilité dans l\'arbre',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          _PrivacyOption(
            icon: Icons.lock_outline,
            title: 'Privé',
            description: 'Ce membre est visible uniquement par vous.',
            value: 'PRIVE',
            groupValue: _visibilite,
            onChanged: (v) => setState(() => _visibilite = v),
          ),
          _PrivacyOption(
            icon: Icons.group_outlined,
            title: 'Partagé',
            description: 'Visible par les membres que vous autorisez.',
            value: 'PARTAGE',
            groupValue: _visibilite,
            onChanged: (v) => setState(() => _visibilite = v),
          ),
          _PrivacyOption(
            icon: Icons.public,
            title: 'Public',
            description: 'Visible par tous les utilisateurs d\'ORIGINE.',
            value: 'PUBLIC',
            groupValue: _visibilite,
            onChanged: (v) => setState(() => _visibilite = v),
          ),
          const SizedBox(height: 20),
          const Text('Options de participation',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          SwitchListTile(
            value: _peutVoir,
            onChanged: (v) => setState(() => _peutVoir = v),
            title: const Text('Autoriser à voir ce membre'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _peutModifier,
            onChanged: (v) => setState(() => _peutModifier = v),
            title: const Text('Autoriser à modifier les informations'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _peutAjouterDocuments,
            onChanged: (v) => setState(() => _peutAjouterDocuments = v),
            title: const Text('Autoriser à ajouter des documents'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _peutAjouterSouvenirs,
            onChanged: (v) => setState(() => _peutAjouterSouvenirs = v),
            title: const Text('Autoriser à ajouter des souvenirs'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _peutCommenter,
            onChanged: (v) => setState(() => _peutCommenter = v),
            title: const Text('Autoriser à commenter'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Card(
      color: selected ? AppColors.vertForet.withOpacity(0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.vertForet : AppColors.grisClair),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        activeColor: AppColors.vertForet,
        secondary: Icon(icon, color: AppColors.vertForet),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
