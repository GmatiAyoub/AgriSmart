import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:agrismart/services/traduction_service.dart';

enum EtatTraduction { initial, chargementModele, traductionEnCours, succes, erreur }

enum LangueApp { fr, ar }

class TraductionProvider extends ChangeNotifier {
  final TraductionService _service;

  TraductionProvider(this._service) {
    _detecterLangueSysteme();
  }

  LangueApp _langueActuelle = LangueApp.fr;
  EtatTraduction _etat = EtatTraduction.initial;
  String _texteTraduit = '';
  String _erreur = '';
  bool _modelePret = false;

  /// Détecte automatiquement la langue du téléphone au démarrage
  void _detecterLangueSysteme() {
    try {
      final localeSysteme = WidgetsBinding.instance.platformDispatcher.locale;
      if (localeSysteme.languageCode.toLowerCase().startsWith('ar')) {
        _langueActuelle = LangueApp.ar;
      } else {
        _langueActuelle = LangueApp.fr;
      }
    } catch (_) {
      _langueActuelle = LangueApp.fr;
    }
  }

  LangueApp get langueActuelle => _langueActuelle;
  bool get estArabe => _langueActuelle == LangueApp.ar;
  Locale get locale => _langueActuelle == LangueApp.ar ? const Locale('ar') : const Locale('fr');

  EtatTraduction get etat => _etat;
  String get texteTraduit => _texteTraduit;
  String get erreur => _erreur;
  bool get modelePret => _modelePret;

  void basculerLangue() {
    _langueActuelle = _langueActuelle == LangueApp.fr ? LangueApp.ar : LangueApp.fr;
    notifyListeners();
  }

  void fixerLangue(LangueApp langue) {
    _langueActuelle = langue;
    notifyListeners();
  }

  /// Traduction d'une clé de texte selon la langue sélectionnée
  String tr(String cle) {
    if (_langueActuelle == LangueApp.ar) {
      return _dicoArabe[cle] ?? _dicoFrancais[cle] ?? cle;
    }
    return _dicoFrancais[cle] ?? cle;
  }

  static const Map<String, String> _dicoFrancais = {
    // Navigation
    'zones': 'Zones',
    'statistiques': 'Statistiques',
    'profil': 'Profil',
    'appTitle': 'AgriSmart',

    // Météo
    'meteoKebili': 'Météo à Kébili',
    'humiditeAir': "Humidité de l'air",
    'vent': 'Vent',
    'aujourdhui': "Aujourd'hui",
    'demain': 'Demain',
    'apresDemain': 'Après-demain',
    'chargementMeteo': 'Chargement de la météo...',
    'reessayer': 'Réessayer',
    'pluiePrevue': 'Pluie prévue',
    'repousserIrrigation': 'repoussez l\'irrigation',
    'pasDePluie': 'Pas de pluie significative prévue',
    'traduireArabe': 'Traduire en arabe',
    'traductionEnCours': 'Traduction en cours...',

    // Stats & Exploitation
    'aIrriguer': 'À irriguer',
    'solCorrect': 'Sol correct',
    'humiditeMin': 'Humidité min.',
    'humiditeMoyenne': 'Humidité moyenne',
    'exploitationHeader': 'Exploitation AgriSmart',
    'zonesSuivies': 'Zones suivies',
    'zonesAIrriguer': 'Zones à irriguer',
    'statSentence': 'zone(s) sur',
    'statSentenceEnd': 'à irriguer',
    'humiditeParZone': 'Humidité par zone',
    'aucuneDonnee': 'Aucune donnée à afficher',
    'aucuneZone': 'Aucune zone pour le moment',
    'besoinIrrigation': "Besoin d'irrigation",

    // Profil & À propos
    'aPropos': 'À propos',
    'seDeconnecter': 'Se déconnecter',
    'confirmerDeconnexion': 'Se déconnecter ?',
    'annuler': 'Annuler',
    'version': 'Version 1.0.0',
    'retour': 'Retour',
    'descriptionApp': "Application de suivi des zones d'une exploitation agricole, développée dans le cadre de l'atelier Framework Cross-Platform à l'ISET Kébili.",
    'traductionTitre': 'Traduction automatique (ML Kit)',
    'saisirTexte': 'Saisissez un texte à traduire en arabe',

    // Auth
    'connexion': 'Se connecter',
    'inscription': 'Créer un compte',
    'email': 'Email',
    'motDePasse': 'Mot de passe',
    'confirmerMotDePasse': 'Confirmer le mot de passe',
    'nom': 'Nom',
    'motDePasseOublie': 'Mot de passe oublié ?',
    'pasDeCompte': "Pas de compte ? S'inscrire",
    'saisirEmail': "Saisissez d'abord votre email",
    'emailEnvoye': 'Email de réinitialisation envoyé',
    'creerMonCompte': 'Créer mon compte',

    // Zones Detail / Form
    'nouvelleZone': 'Nouvelle zone',
    'modifierZone': 'Modifier la zone',
    'supprimerZone': 'Supprimer la zone ?',
    'supprimer': 'Supprimer',
    'zoneAjoutee': 'Zone ajoutée',
    'zoneModifiee': 'Zone modifiée',
    'zoneSupprimee': 'Zone supprimée',
    'humActuelle': 'Humidité actuelle',
    'seuilIrrigation': "Seuil d'irrigation",
    'vanne': 'Vanne',
    'ouverte': 'Ouverte',
    'fermee': 'Fermée',
    'modifierCetteZone': 'Modifier cette zone',
    'nomZone': 'Nom de la zone',
    'culture': 'Culture',
    'seuilPercent': "Seuil d'irrigation (%)",
    'enregistrer': 'Enregistrer',
  };

  static const Map<String, String> _dicoArabe = {
    // Navigation
    'zones': 'المناطق',
    'statistiques': 'الإحصائيات',
    'profil': 'الملف الشخصي',
    'appTitle': 'AgriSmart',

    // Météo
    'meteoKebili': 'الطقس في قبلي',
    'humiditeAir': 'رطوبة الهواء',
    'vent': 'الرياح',
    'aujourdhui': 'اليوم',
    'demain': 'غداً',
    'apresDemain': 'بعد غد',
    'chargementMeteo': 'جاري تحميل الطقس...',
    'reessayer': 'إعادة المحاولة',
    'pluiePrevue': 'أمطار متوقعة',
    'repousserIrrigation': 'تأجيل الري',
    'pasDePluie': 'لا توجد أمطار هامة متوقعة',
    'traduireArabe': 'ترجمة للعربية',
    'traductionEnCours': 'جاري الترجمة...',

    // Stats & Exploitation
    'aIrriguer': 'يحتاج للري',
    'solCorrect': 'التربة جيدة',
    'humiditeMin': 'الرطوبة الأدنى',
    'humiditeMoyenne': 'معدل الرطوبة',
    'exploitationHeader': 'مزرعة AgriSmart',
    'zonesSuivies': 'المناطق المتابعة',
    'zonesAIrriguer': 'المناطق التي تحتاج للري',
    'statSentence': 'منطقة (مناطق) من',
    'statSentenceEnd': 'تحتاج للري',
    'humiditeParZone': 'الرطوبة حسب المنطقة',
    'aucuneDonnee': 'لا توجد بيانات للعرض',
    'aucuneZone': 'لا توجد مناطق حالياً',
    'besoinIrrigation': 'يحتاج إلى الري',

    // Profil & À propos
    'aPropos': 'حول التطبيق',
    'seDeconnecter': 'تسجيل الخروج',
    'confirmerDeconnexion': 'هل تريد تسجيل الخروج؟',
    'annuler': 'إلغاء',
    'version': 'الإصدار 1.0.0',
    'retour': 'عودة',
    'descriptionApp': 'تطبيق متابعة مناطق المزرعة، تم تطويره في إطار ورشة العمل للمنصات المتعددة في المعهد العالي للدراسات التكنولوجية بقبلي.',
    'traductionTitre': 'الترجمة الآلية (ML Kit)',
    'saisirTexte': 'أدخل نصاً للترجمة إلى العربية',

    // Auth
    'connexion': 'تسجيل الدخول',
    'inscription': 'إنشاء حساب',
    'email': 'البريد الإلكتروني',
    'motDePasse': 'كلمة المرور',
    'confirmerMotDePasse': 'تأكيد كلمة المرور',
    'nom': 'الاسم',
    'motDePasseOublie': 'نسيت كلمة المرور؟',
    'pasDeCompte': 'ليس لديك حساب؟ سجل الآن',
    'saisirEmail': 'أدخل بريدك الإلكتروني أولاً',
    'emailEnvoye': 'تم إرسال بريد إعادة تعيين كلمة المرور',
    'creerMonCompte': 'إنشاء حسابي',

    // Zones Detail / Form
    'nouvelleZone': 'منطقة جديدة',
    'modifierZone': 'تعديل المنطقة',
    'supprimerZone': 'حذف المنطقة؟',
    'supprimer': 'حذف',
    'zoneAjoutee': 'تمت إضافة المنطقة',
    'zoneModifiee': 'تم تعديل المنطقة',
    'zoneSupprimee': 'تم حذف المنطقة',
    'humActuelle': 'الرطوبة الحالية',
    'seuilIrrigation': 'عتبة الري',
    'vanne': 'الصمام',
    'ouverte': 'مفتوح',
    'fermee': 'مغلق',
    'modifierCetteZone': 'تعديل هذه المنطقة',
    'nomZone': 'اسم المنطقة',
    'culture': 'المحصول',
    'seuilPercent': 'عتبة الري (%)',
    'enregistrer': 'حفظ',
  };

  /// Méthodes ML Kit dynamiques
  Future<void> preparerModele(TranslateLanguage langue) async {
    _etat = EtatTraduction.chargementModele;
    _erreur = '';
    notifyListeners();

    try {
      final installe = await _service.estModeleInstalle(langue);
      if (!installe) {
        await _service.telechargerModele(langue);
      }
      _modelePret = true;
      _etat = EtatTraduction.initial;
    } on TraductionException catch (e) {
      _erreur = e.message;
      _etat = EtatTraduction.erreur;
      _modelePret = false;
    } catch (e) {
      _erreur = 'Erreur lors de la préparation du modèle : $e';
      _etat = EtatTraduction.erreur;
      _modelePret = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> traduire(String texte, TranslateLanguage source, TranslateLanguage cible) async {
    if (!_modelePret) {
      await preparerModele(cible);
      if (!_modelePret) {
        return;
      }
    }

    _etat = EtatTraduction.traductionEnCours;
    _erreur = '';
    notifyListeners();

    try {
      _texteTraduit = await _service.traduire(texte, source, cible);
      _etat = EtatTraduction.succes;
    } on TraductionException catch (e) {
      _erreur = e.message;
      _etat = EtatTraduction.erreur;
    } catch (e) {
      _erreur = 'Erreur lors de la traduction : $e';
      _etat = EtatTraduction.erreur;
    } finally {
      notifyListeners();
    }
  }
}
