from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class ReporteGenerado(Base):
    __tablename__ = "reportes_generados"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tipo: Mapped[str] = mapped_column(String(60), nullable=False)
    parametros: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    resultado: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    generado_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
