from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Pedido(Base):
    __tablename__ = "pedidos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    carne: Mapped[str] = mapped_column(String(20), nullable=False)
    estado: Mapped[str] = mapped_column(String(20), nullable=False, default="confirmado")
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, default=0)
    creado_en: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    lineas: Mapped[list["PedidoLinea"]] = relationship(
        back_populates="pedido", cascade="all, delete-orphan", lazy="selectin"
    )


class PedidoLinea(Base):
    __tablename__ = "pedido_lineas"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    pedido_id: Mapped[int] = mapped_column(ForeignKey("pedidos.id", ondelete="CASCADE"), nullable=False)
    sku: Mapped[str] = mapped_column(String(40), nullable=False)
    cantidad: Mapped[int] = mapped_column(Integer, nullable=False)
    precio_unitario: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    pedido: Mapped[Pedido] = relationship(back_populates="lineas")
