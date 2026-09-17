# app/models/__init__.py
# Import centralisé pour que SQLAlchemy découvre tous les modèles
# lors de l'appel à Base.metadata.create_all()

from .user import User, RefreshToken, LoginAttempt       # noqa: F401
from .genealogy import (                                  # noqa: F401
    Tribe, Clan, Family, FamilyShare, Person, Relationship,
    PersonDocument, PersonMemory
)
from .ai import AIProvider, AILog                         # noqa: F401
from .story import (                                      # noqa: F401
    Story, StoryMedia, StoryLike, StoryComment, StoryReport, CertificationRequest
)
from .family_chat import FamilyGroup, FamilyGroupMember, FamilyMessage  # noqa: F401
from .event import FamilyEvent                             # noqa: F401
from .push import PushSubscription                         # noqa: F401
