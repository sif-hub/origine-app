# app/services/ai_service.py

import time
import json
import httpx
from typing import Optional
from sqlalchemy.orm import Session
from ..core.config import settings
from ..models.ai import AILog, AIProvider


FALLBACK_ORDER = ["CLAUDE", "OPENAI", "GEMINI", "DEEPSEEK"]


class AIManager:
    def __init__(self, db: Session):
        self.db = db

    def ask(
        self,
        system_prompt: str,
        user_prompt: str,
        type_requete: str,
        user_id: Optional[int],
        options: dict = {},
    ) -> str:
        active_provider = self._get_active_provider_name()
        order = list(dict.fromkeys([active_provider] + FALLBACK_ORDER))
        last_error = None

        for provider_name in order:
            start = time.time()
            try:
                response = self._call_provider(provider_name, system_prompt, user_prompt, options)
                duration = int((time.time() - start) * 1000)
                self._log(user_id, provider_name, type_requete, user_prompt, response, "SUCCES", duration)
                return response
            except Exception as e:
                duration = int((time.time() - start) * 1000)
                self._log(user_id, provider_name, type_requete, user_prompt, str(e), "ECHEC", duration)
                last_error = e
                continue

        raise RuntimeError(f"Tous les fournisseurs IA sont indisponibles. Dernière erreur : {last_error}")

    def _get_active_provider_name(self) -> str:
        provider = self.db.query(AIProvider).filter(AIProvider.actif == 1).first()
        return provider.nom if provider else settings.AI_PROVIDER

    def _call_provider(self, name: str, system: str, user: str, options: dict) -> str:
        max_tokens = options.get("max_tokens", 800)
        temperature = options.get("temperature", 0.5)

        if name == "CLAUDE":
            return self._call_claude(system, user, max_tokens)
        elif name == "OPENAI":
            return self._call_openai(system, user, max_tokens, temperature)
        elif name == "GEMINI":
            return self._call_gemini(system, user, max_tokens)
        elif name == "DEEPSEEK":
            return self._call_deepseek(system, user, max_tokens, temperature)
        else:
            raise ValueError(f"Fournisseur inconnu : {name}")

    def _call_claude(self, system: str, user: str, max_tokens: int) -> str:
        if not settings.CLAUDE_API_KEY:
            raise RuntimeError("Clé API Claude non configurée (CLAUDE_API_KEY).")

        with httpx.Client(timeout=30) as client:
            r = client.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": settings.CLAUDE_API_KEY,
                    "anthropic-version": "2023-06-01",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "claude-sonnet-4-6",
                    "system": system,
                    "max_tokens": max_tokens,
                    "messages": [{"role": "user", "content": user}],
                },
            )
            r.raise_for_status()
            return r.json()["content"][0]["text"]

    def _call_openai(self, system: str, user: str, max_tokens: int, temperature: float) -> str:
        if not settings.OPENAI_API_KEY:
            raise RuntimeError("Clé API OpenAI non configurée (OPENAI_API_KEY).")

        with httpx.Client(timeout=30) as client:
            r = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "gpt-4o",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": user},
                    ],
                    "max_tokens": max_tokens,
                    "temperature": temperature,
                },
            )
            r.raise_for_status()
            return r.json()["choices"][0]["message"]["content"]

    def _call_gemini(self, system: str, user: str, max_tokens: int) -> str:
        if not settings.GEMINI_API_KEY:
            raise RuntimeError("Clé API Gemini non configurée (GEMINI_API_KEY).")

        # Alias "toujours à jour" plutôt qu'un modèle figé : évite de retomber sur
        # un modèle retiré (cas de gemini-1.5-pro) et a son propre quota gratuit,
        # séparé de celui des modèles nommés explicitement (ex: gemini-3.6-flash),
        # ce qui limite le risque de tomber à sec en cas de forte utilisation.
        model = "gemini-flash-latest"
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={settings.GEMINI_API_KEY}"

        with httpx.Client(timeout=30) as client:
            r = client.post(url, json={
                "contents": [{"role": "user", "parts": [{"text": f"{system}\n\n{user}"}]}],
                "generationConfig": {
                    "maxOutputTokens": max_tokens,
                    # Les modèles Gemini récents sont des modèles "thinking" : sans
                    # ceci, ils consomment le budget de tokens en raisonnement interne
                    # invisible et tronquent la réponse visible avant qu'elle ne soit
                    # terminée (finishReason MAX_TOKENS). On désactive le thinking
                    # pour des réponses rapides et complètes, adaptées à un assistant
                    # conversationnel.
                    "thinkingConfig": {"thinkingBudget": 0},
                },
            })
            r.raise_for_status()
            data = r.json()
            candidate = data["candidates"][0]
            parts = candidate.get("content", {}).get("parts", [])
            text = "".join(p.get("text", "") for p in parts if not p.get("thought"))
            if not text:
                raise RuntimeError(
                    f"Réponse Gemini vide (finishReason={candidate.get('finishReason')})."
                )
            return text

    def _call_deepseek(self, system: str, user: str, max_tokens: int, temperature: float) -> str:
        if not settings.DEEPSEEK_API_KEY:
            raise RuntimeError("Clé API DeepSeek non configurée (DEEPSEEK_API_KEY).")

        with httpx.Client(timeout=30) as client:
            r = client.post(
                "https://api.deepseek.com/chat/completions",
                headers={
                    "Authorization": f"Bearer {settings.DEEPSEEK_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": user},
                    ],
                    "max_tokens": max_tokens,
                    "temperature": temperature,
                },
            )
            r.raise_for_status()
            return r.json()["choices"][0]["message"]["content"]

    def _log(self, user_id, provider_name, type_requete, prompt, reponse, statut, duree_ms):
        try:
            provider = self.db.query(AIProvider).filter(AIProvider.nom == provider_name).first()
            self.db.add(AILog(
                user_id=user_id,
                provider_id=provider.id if provider else None,
                type_requete=type_requete,
                prompt=prompt[:5000],
                reponse=reponse[:8000],
                statut=statut,
                duree_ms=duree_ms,
            ))
            self.db.commit()
        except Exception:
            pass  # Le logging ne doit jamais bloquer la réponse principale


# ─── Assistants spécialisés ──────────────────────────────────────────────

def chat(db: Session, message: str, historique: list, user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = (
        "Tu es ORIGINE AI, l'assistant conversationnel de la plateforme ORIGINE, "
        "dédiée à la généalogie et au patrimoine culturel camerounais. "
        "Tu réponds en français, de manière chaleureuse et concise. "
        "Tu n'inventes jamais de faits généalogiques ou historiques précis."
    )

    context = "\n".join(
        f"{'Utilisateur' if m['role'] == 'user' else 'Assistant'} : {m['content'][:500]}"
        for m in historique[-10:]
    )
    full_prompt = f"{context}\n\nUtilisateur : {message}" if context else message

    return ai.ask(system, full_prompt, "CHATBOT", user_id, {"max_tokens": 700})


def natural_search(db: Session, requete: str, user_id: Optional[int]) -> dict:
    ai = AIManager(db)
    system = (
        "Tu es un moteur d'interprétation de requêtes pour une plateforme généalogique camerounaise. "
        'Réponds UNIQUEMENT avec un JSON valide sans markdown : '
        '{"intention": "DESCENDANTS|ANCETRES|PERSONNAGE_HISTORIQUE|PERSONNE|FAMILLE_PAR_LIEU", '
        '"filtres": {"nom": null, "prenom": null, "sexe": null, "annee_naissance": null, '
        '"village": null, "region": null, "tribu": null, "clan": null}}'
    )

    raw = ai.ask(system, requete, "RECHERCHE_NATURELLE", user_id, {"max_tokens": 300, "temperature": 0.1})

    try:
        cleaned = raw.strip().lstrip("```json").rstrip("```").strip()
        criteres = json.loads(cleaned)
    except Exception:
        criteres = {"intention": "PERSONNE", "filtres": {}}

    return criteres


def explain_tradition(db: Session, nom: str, region: Optional[str], user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = (
        "Tu es l'Assistant Culturel d'ORIGINE, spécialisé dans les cultures, traditions, "
        "langues et tribus du Cameroun. Tu expliques avec respect et précision."
    )
    prompt = (
        f"Explique la tradition camerounaise '{nom}'"
        f"{' (région : ' + region + ')' if region else ''}. "
        "Mentionne son origine, sa signification et son importance culturelle. "
        "Si tu n'es pas certain d'un détail, indique-le."
    )
    return ai.ask(system, prompt, "CULTURE", user_id, {"max_tokens": 500})


def explain_name(db: Session, nom: str, tribu: Optional[str], user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = (
        "Tu es l'Assistant Culturel d'ORIGINE, spécialisé dans les noms camerounais. "
        "Tu expliques les significations et origines avec précision et nuance."
    )
    prompt = (
        f"Explique la signification et l'origine du nom camerounais '{nom}'"
        f"{' (tribu : ' + tribu + ')' if tribu else ''}. "
        "Mentionne les variantes et l'histoire si tu les connais."
    )
    return ai.ask(system, prompt, "CULTURE", user_id, {"max_tokens": 400})


def explain_clan(db: Session, nom: str, tribu: Optional[str], user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = "Tu es l'Assistant Culturel d'ORIGINE, expert en clans et tribus camerounais."
    prompt = (
        f"Explique le clan '{nom}'"
        f"{' de la tribu ' + tribu if tribu else ''} : "
        "son rôle social, ses origines et son importance dans la structure familiale traditionnelle."
    )
    return ai.ask(system, prompt, "CULTURE", user_id, {"max_tokens": 400})


def summarize_story(db: Session, contenu: str, user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = (
        "Tu es l'Assistant Historique d'ORIGINE. Tu résumes des histoires familiales "
        "de manière concise et respectueuse. Tu n'inventes jamais de faits."
    )
    return ai.ask(system, f"Résume en 3 phrases : {contenu}", "HISTOIRE", user_id, {"max_tokens": 300})


def draft_narrative(db: Session, notes: str, user_id: Optional[int]) -> str:
    ai = AIManager(db)
    system = (
        "Tu es l'Assistant Historique d'ORIGINE. Tu transformes des notes brutes en récits "
        "fluides et chronologiques, sans inventer de faits au-delà de ce qui est fourni."
    )
    return ai.ask(system, f"Rédige un récit à partir de ces notes :\n{notes}", "HISTOIRE", user_id, {"max_tokens": 800})
