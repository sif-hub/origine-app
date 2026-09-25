// lib/features/stories/presentation/screens/add_story_wizard_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/story_model.dart';
import '../../../auth/domain/auth_bloc.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/stories_repository.dart';
import '../../domain/add_story_bloc.dart';
import 'story_published_screen.dart';

const _professionalTypeLabels = {
  'GRIOT': 'Griot',
  'GENEALOGISTE': 'Généalogiste',
  'HISTORIEN': 'Historien',
  'AUTRE': 'Autre',
};

class AddStoryWizardScreen extends StatelessWidget {
  const AddStoryWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddStoryBloc(StoriesRepository()),
      child: const _AddStoryWizardView(),
    );
  }
}

class _AddStoryWizardView extends StatefulWidget {
  const _AddStoryWizardView();

  @override
  State<_AddStoryWizardView> createState() => _AddStoryWizardViewState();
}

class _AddStoryWizardViewState extends State<_AddStoryWizardView> {
  final _pageController = PageController();
  int _step = 0;

  // Statut de certification de l'auteur, chargé au démarrage : la demande ne se
  // fait qu'une fois — l'étape "Auteur" disparaît si l'auteur est déjà certifié
  // ou si sa demande est en cours d'examen (elle reste possible après un refus).
  // null = en cours de chargement.
  String? _certStatus; // NONE | EN_ATTENTE | APPROUVEE | REJETEE | CERTIFIE
  bool get _askAuthorStep =>
      _certStatus == null || _certStatus == 'NONE' || _certStatus == 'REJETEE';
  int get _stepCount => _askAuthorStep ? 4 : 3;

  // Étape 1
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime? _dateHistoire;
  String? _region;
  final _villageCtrl = TextEditingController();
  String _categorie = 'AUTRE';

  // Étape 2
  final List<DraftStoryMedia> _media = [];
  final _motsClesCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  bool _autoriserTts = true;

  // Étape 3
  bool _estProfessionnel = false;
  String _typeProfessionnel = 'GRIOT';
  final _descriptionProCtrl = TextEditingController();
  DraftStoryMedia? _document;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated && auth.user.certifie) {
      _certStatus = 'CERTIFIE';
    } else {
      _loadCertificationStatus();
    }
  }

  Future<void> _loadCertificationStatus() async {
    String status = 'NONE';
    try {
      final req = await StoriesRepository().getMyCertificationStatus();
      status = (req?['statut'] as String?) ?? 'NONE';
    } catch (_) {
      // En cas d'échec réseau, on laisse l'étape visible : le serveur refuse de
      // toute façon une demande en double.
    }
    if (!mounted) return;
    setState(() {
      _certStatus = status;
      if (_step > _stepCount - 1) _step = _stepCount - 1;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _titreCtrl, _descriptionCtrl, _villageCtrl, _motsClesCtrl, _sourceCtrl, _descriptionProCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canGoNext {
    if (_step == 0) return _titreCtrl.text.trim().isNotEmpty && _descriptionCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    if (_step == _stepCount - 1) {
      _submit();
      return;
    }
    if (!_canGoNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et la description sont obligatoires.')),
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
    final draft = StoryDraft(
      titre: _titreCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      dateHistoire: _dateHistoire?.toIso8601String().split('T').first,
      region: _region,
      village: _emptyToNull(_villageCtrl.text),
      categorie: _categorie,
      motsCles: _emptyToNull(_motsClesCtrl.text),
      source: _emptyToNull(_sourceCtrl.text),
      autoriserTts: _autoriserTts,
      media: _media,
      estProfessionnel: _askAuthorStep && _estProfessionnel,
      typeProfessionnel: _askAuthorStep && _estProfessionnel ? _typeProfessionnel : null,
      descriptionProfessionnelle:
          _askAuthorStep && _estProfessionnel ? _emptyToNull(_descriptionProCtrl.text) : null,
      documentJustificatif: _askAuthorStep && _estProfessionnel ? _document : null,
    );
    context.read<AddStoryBloc>().add(SubmitStoryRequested(draft));
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddStoryBloc, AddStoryState>(
      listener: (context, state) {
        if (state is AddStorySuccess) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => StoryPublishedScreen(story: state.story),
          ));
        } else if (state is AddStoryFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter une histoire'),
          leading: BackButton(onPressed: _previous),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: WizardStepIndicator(
                stepCount: _stepCount,
                currentStep: _step,
                labels: [
                  'Histoire',
                  'Médias',
                  if (_askAuthorStep) 'Auteur',
                  'Aperçu',
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInfoStep(),
                  _buildMediaStep(),
                  if (_askAuthorStep) _buildAuthorStep(),
                  _buildPreviewStep(),
                ],
              ),
            ),
            BlocBuilder<AddStoryBloc, AddStoryState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(16),
                child: AppPrimaryButton(
                  label: _step == _stepCount - 1 ? 'Publier l\'histoire' : 'Suivant',
                  isLoading: state is AddStorySubmitting,
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

  String _authorSummary() {
    if (_certStatus == 'CERTIFIE' || _certStatus == 'APPROUVEE') return 'Auteur certifié(e)';
    if (_certStatus == 'EN_ATTENTE') return 'Certification en cours d\'examen';
    return _estProfessionnel
        ? 'Professionnel (${_professionalTypeLabels[_typeProfessionnel]})'
        : 'Utilisateur lambda';
  }

  // ── ÉTAPE 1 : INFORMATIONS ────────────────────────────────────────
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Votre histoire',
            subtitle: 'Partagez un récit, une tradition ou un souvenir qui mérite de perdurer.',
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Titre de l\'histoire *', controller: _titreCtrl),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Racontez votre histoire *',
            controller: _descriptionCtrl,
            maxLines: 6,
            hint: 'Décrivez les faits, les personnes, les traditions...',
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateHistoire ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dateHistoire = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date de l\'histoire'),
              child: Text(_dateHistoire == null
                  ? 'JJ / MM / AAAA'
                  : '${_dateHistoire!.day.toString().padLeft(2, '0')}/${_dateHistoire!.month.toString().padLeft(2, '0')}/${_dateHistoire!.year}'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _region,
            decoration: const InputDecoration(labelText: 'Région concernée'),
            items: kCameroonRegions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _region = v),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Village / localité (optionnel)', controller: _villageCtrl),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categorie,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: kStoryCategories.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _categorie = v ?? 'AUTRE'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 2 : MÉDIAS ───────────────────────────────────────────────
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    for (final f in files) {
      final bytes = await f.readAsBytes();
      setState(() => _media.add(DraftStoryMedia(type: 'PHOTO', bytes: bytes, filename: f.name)));
    }
  }

  Future<void> _pickAudioVideo(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'VIDEO' ? FileType.video : FileType.audio,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _media.add(DraftStoryMedia(type: type, bytes: file!.bytes!, filename: file.name)));
  }

  Widget _buildMediaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Médias',
            subtitle: 'Illustrez votre histoire avec des photos, vidéos ou audios.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ajouter des photos'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickAudioVideo('VIDEO'),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Ajouter une vidéo'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickAudioVideo('AUDIO'),
                icon: const Icon(Icons.mic_none_outlined),
                label: const Text('Enregistrer un audio'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_media.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _media.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final m = _media[i];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grisClair,
                        borderRadius: BorderRadius.circular(10),
                        image: m.type == 'PHOTO'
                            ? DecorationImage(image: MemoryImage(m.bytes), fit: BoxFit.cover)
                            : null,
                      ),
                      child: m.type != 'PHOTO'
                          ? Center(
                              child: Icon(m.type == 'VIDEO' ? Icons.videocam : Icons.audiotrack,
                                  color: AppColors.vertForet),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _media.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 11, backgroundColor: AppColors.erreur,
                          child: Icon(Icons.close, size: 14, color: AppColors.blanc),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 20),
          AppTextField(
              label: 'Mots-clés (optionnel)', controller: _motsClesCtrl,
              hint: 'tradition, danse, rite...'),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Source de l\'information (optionnel)', controller: _sourceCtrl,
              hint: 'livre, témoignage, famille...'),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _autoriserTts,
            onChanged: (v) => setState(() => _autoriserTts = v),
            title: const Text('Autoriser l\'écoute de l\'histoire (synthèse vocale)'),
            activeColor: AppColors.vertForet,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 3 : STATUT DE L'AUTEUR ───────────────────────────────────
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _document = DraftStoryMedia(type: 'DOCUMENT', bytes: file!.bytes!, filename: file.name));
  }

  Widget _buildAuthorStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Statut de l\'auteur',
            subtitle: 'Vous êtes un professionnel de la transmission historique ?',
          ),
          if (_certStatus == 'REJETEE') ...[
            const SizedBox(height: 12),
            const AppBanner(
              message: 'Votre précédente demande de certification a été refusée. '
                  'Vous pouvez en soumettre une nouvelle avec un autre justificatif.',
            ),
          ],
          const SizedBox(height: 16),
          RadioListTile<bool>(
            value: false,
            groupValue: _estProfessionnel,
            onChanged: (v) => setState(() => _estProfessionnel = v ?? false),
            activeColor: AppColors.vertForet,
            title: const Text('Utilisateur lambda (particulier)'),
            subtitle: const Text('Je souhaite simplement partager mon histoire.'),
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: _estProfessionnel,
            onChanged: (v) => setState(() => _estProfessionnel = v ?? false),
            activeColor: AppColors.vertForet,
            title: const Text('Je suis un professionnel ou détenteur du savoir'),
            subtitle: const Text('Griot, généalogiste, historien, chercheur...'),
          ),
          if (_estProfessionnel) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _typeProfessionnel,
              decoration: const InputDecoration(labelText: 'Quel est votre statut ?'),
              items: _professionalTypeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _typeProfessionnel = v ?? 'GRIOT'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Description de votre parcours (facultatif)',
              controller: _descriptionProCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.upload_file_outlined, color: AppColors.vertForet),
                title: Text(_document?.filename ?? 'Importer un document justificatif *'),
                subtitle: const Text('Le document sera vérifié par l\'administrateur.'),
                trailing: TextButton(onPressed: _pickDocument, child: const Text('Importer')),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── ÉTAPE 4 : APERÇU ───────────────────────────────────────────────
  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Aperçu',
            subtitle: 'Vérifiez les informations avant de publier.',
          ),
          const SizedBox(height: 16),
          AppInfoCard(
            title: _titreCtrl.text.trim().isEmpty ? '(sans titre)' : _titreCtrl.text.trim(),
            rows: [
              InfoRow('Description', _descriptionCtrl.text.trim()),
              if (_region != null) InfoRow('Région', _region!),
              if (_villageCtrl.text.trim().isNotEmpty) InfoRow('Village', _villageCtrl.text.trim()),
              InfoRow('Catégorie', kStoryCategories[_categorie] ?? _categorie),
              InfoRow('Médias', '${_media.length} fichier(s)'),
              InfoRow('Auteur', _authorSummary()),
              InfoRow('Écoute (TTS)', _autoriserTts ? 'Activée' : 'Désactivée'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
