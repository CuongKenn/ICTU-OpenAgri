"""Integration with Google Gemini for agriculture chatbot."""
from __future__ import annotations

import json
import logging
import os
from typing import Dict, List, Sequence

import google.generativeai as genai

from app.infrastructure.config.settings import get_settings

logger = logging.getLogger(__name__)

DEFAULT_SYSTEM_PROMPT = (
    "Bạn là trợ lý AI chuyên gia nông nghiệp Việt Nam. Luôn trả lời bằng tiếng Việt, "
    "dựa trên các thực hành canh tác bền vững, tư vấn cho nông dân về cây trồng, "
    "sâu bệnh, thời tiết và thị trường. Giải thích ngắn gọn, thực tế, đề xuất các bước "
    "hành động cụ thể và nhắc nhở tham khảo chuyên gia địa phương cho quyết định quan trọng."
)


class GeminiAgricultureAssistant:
    """Wrapper around Google Gemini focused on agriculture guidance."""

    def __init__(self) -> None:
        self.settings = get_settings()
        if not self.settings.GEMINI_API_KEY:
            raise ValueError("Thiếu GEMINI_API_KEY trong cấu hình. Vui lòng thiết lập trước khi gọi chatbot.")

        genai.configure(api_key=self.settings.GEMINI_API_KEY)

        system_instruction = (self.settings.GEMINI_SYSTEM_PROMPT or "").strip()
        if not system_instruction:
            logger.warning(
                "GEMINI_SYSTEM_PROMPT is empty. Using default agriculture assistant prompt."
            )
            system_instruction = DEFAULT_SYSTEM_PROMPT

        # Use temperature from settings or default
        temperature = getattr(self.settings, 'GEMINI_TEMPERATURE', 0.9)
        top_p = getattr(self.settings, 'GEMINI_TOP_P', 1.0)
        top_k = getattr(self.settings, 'GEMINI_TOP_K', 64)

        # Configure model with relaxed safety settings
        # NOTE: safety_settings needs to be applied at generation time, not model init
        self.model = genai.GenerativeModel(
            model_name=self.settings.GEMINI_MODEL,
            system_instruction=system_instruction,
            generation_config={
                "temperature": temperature,
                "top_p": top_p,
                "top_k": top_k,
                "max_output_tokens": 2048,
            },
        )
        
        # Store safety settings for use during generation
        self.safety_settings = [
            {
                "category": "HARM_CATEGORY_HARASSMENT",
                "threshold": "BLOCK_NONE",
            },
            {
                "category": "HARM_CATEGORY_HATE_SPEECH",
                "threshold": "BLOCK_NONE",
            },
            {
                "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                "threshold": "BLOCK_NONE",
            },
            {
                "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                "threshold": "BLOCK_NONE",
            },
        ]

        self._knowledge_base = self._load_knowledge()

    def _load_knowledge(self) -> List[Dict[str, object]]:
        knowledge_path = self.settings.GEMINI_KNOWLEDGE_PATH
        if not knowledge_path:
            logger.warning("Không tìm thấy đường dẫn knowledge base cho chatbot.")
            return []

        if not os.path.exists(knowledge_path):
            logger.warning("Tệp knowledge base %s không tồn tại.", knowledge_path)
            return []

        try:
            with open(knowledge_path, "r", encoding="utf-8") as file:
                data = json.load(file)
                if isinstance(data, list):
                    return data
                logger.warning("Knowledge base không đúng định dạng list.")
        except Exception as exc:
            logger.error("Lỗi khi đọc knowledge base: %s", exc)

        return []

    def _collect_relevant_tips(
        self, question: str, history: Sequence[Dict[str, str]]
    ) -> List[Dict[str, object]]:
        if not self._knowledge_base:
            return []

        corpus = f"{question.lower()}\n" + "\n".join(msg["content"].lower() for msg in history if msg.get("content"))
        matched: List[Dict[str, object]] = []

        for tip in self._knowledge_base:
            keywords = [kw.lower() for kw in tip.get("keywords", [])]
            if any(keyword in corpus for keyword in keywords):
                matched.append(tip)

        # Fallback: surface top 2 default tips if nothing matched
        if not matched:
            matched = self._knowledge_base[:2]

        return matched[:3]

    def _build_context_block(self, tips: Sequence[Dict[str, object]]) -> str:
        if not tips:
            return ""

        context_lines: List[str] = ["Thông tin thực tế từ chuyên gia:"]  # noqa: E501
        for tip in tips:
            title = tip.get("title", "Ghi chú")
            summary = tip.get("summary", "")
            best_practices = tip.get("best_practices", [])
            context_lines.append(f"- {title}: {summary}")
            if best_practices:
                for practice in best_practices[:3]:
                    context_lines.append(f"  • {practice}")

        return "\n".join(context_lines)

    def _extract_response_text(self, response) -> str:
        if not response:
            return ""

        try:
            # Prefer the convenience accessor when it is available.
            text_attr = getattr(response, "text", None)
            if text_attr:
                return text_attr.strip()
        except ValueError:
            logger.debug(
                "Gemini response.text unavailable; attempting to read candidate parts directly."
            )

        parts: List[str] = []
        try:
            for candidate in getattr(response, "candidates", []) or []:
                content = getattr(candidate, "content", None)
                if not content:
                    continue
                content_parts = getattr(content, "parts", None)
                if content_parts is None and isinstance(content, dict):
                    content_parts = content.get("parts", [])

                for part in content_parts or []:
                    if isinstance(part, dict):
                        text_value = part.get("text")
                    else:
                        text_value = getattr(part, "text", None)
                    if isinstance(text_value, str) and text_value.strip():
                        parts.append(text_value.strip())
        except Exception as exc:  # pragma: no cover - defensive logging
            logger.debug("Failed to parse Gemini candidate parts: %s", exc)

        return "\n".join(parts).strip()

    def _log_debug_response(self, response) -> None:
        try:
            logger.debug(
                "Gemini raw response payload: %s",
                getattr(response, "to_dict", lambda: response)(),
            )
        except Exception:  # pragma: no cover - defensive logging
            logger.debug("Gemini response repr: %r", response)

    def _log_safety_ratings(self, response) -> None:
        try:
            for index, candidate in enumerate(getattr(response, "candidates", []) or []):
                safety_ratings = getattr(candidate, "safety_ratings", None)
                finish_reason = getattr(candidate, "finish_reason", "")
                logger.warning(
                    "Gemini candidate %s summary: finish_reason=%s, safety_ratings=%s, content_parts=%s",
                    index,
                    finish_reason,
                    safety_ratings,
                    getattr(getattr(candidate, "content", None), "parts", None),
                )
        except Exception as exc:  # pragma: no cover - defensive logging
            logger.debug("Unable to inspect Gemini safety ratings: %s", exc)

    def _log_prompt_feedback(self, response) -> None:
        feedback = getattr(response, "prompt_feedback", None)
        if not feedback:
            return

        try:
            safety_ratings = getattr(feedback, "safety_ratings", None)
            block_reason = getattr(feedback, "block_reason", None)
            logger.warning(
                "Gemini prompt_feedback: block_reason=%s, safety_ratings=%s",
                block_reason,
                safety_ratings,
            )
        except Exception as exc:  # pragma: no cover - defensive logging
            logger.debug("Unable to log Gemini prompt_feedback: %s", exc)

    def _build_fallback_answer(self, tips: Sequence[Dict[str, object]]) -> str:
        knowledge_lines: List[str] = []
        if tips:
            knowledge_lines.append(
                "Tôi đã tổng hợp nhanh một số gợi ý từ nguồn kiến thức nội bộ:"  # noqa: E501
            )
            for tip in tips[:3]:
                title = tip.get("title", "Gợi ý")
                summary = tip.get("summary", "")
                knowledge_lines.append(f"- {title}: {summary}")

        fallback_body = (
            "\n".join(knowledge_lines)
            if knowledge_lines
            else "Hiện trợ lý AI đang tạm gián đoạn."
        )

        return (
            "Xin lỗi, dịch vụ Gemini đang gặp sự cố nên tôi chưa thể truy vấn câu trả lời trực tuyến. "
            "Dưới đây là thông tin tham khảo nội bộ mà bạn có thể cân nhắc:\n\n"
            f"{fallback_body}\n\nNếu cần thêm trợ giúp, vui lòng thử lại sau hoặc liên hệ chuyên gia địa phương."
        )

    def _prepare_messages(
        self,
        history: Sequence[Dict[str, str]],
        prompt: str,
    ) -> List[Dict[str, object]]:
        messages: List[Dict[str, object]] = []
        for item in history[-8:]:  # limit history to prevent token bloat
            role = item.get("role", "user")
            content = item.get("content", "")
            if not content:
                continue
            gemini_role = "user" if role == "user" else "model"
            messages.append({"role": gemini_role, "parts": [{"text": content}]})

        messages.append({"role": "user", "parts": [{"text": prompt}]})
        return messages

    def generate_answer(
        self,
        question: str,
        history: Sequence[Dict[str, str]],
    ) -> Dict[str, object]:
        # Validate question
        if not question or not question.strip():
            raise ValueError("Câu hỏi không được để trống.")
        
        if len(question.strip()) > 1000:
            raise ValueError("Câu hỏi không được vượt quá 1000 ký tự.")
        
        if len(question.strip()) < 3:
            raise ValueError("Câu hỏi quá ngắn. Vui lòng viết chi tiết hơn.")

        # Validate history
        if not isinstance(history, (list, tuple)):
            raise ValueError("Lịch sử chat không hợp lệ.")
        
        if len(history) > 50:  # Prevent history from growing too large
            logger.warning("Chat history exceeds 50 messages, limiting to last 50")
            history = history[-50:]

        tips = self._collect_relevant_tips(question, history)
        context_block = self._build_context_block(tips)
        prompt = f"{context_block}\n\nCâu hỏi của nông dân: {question.strip()}" if context_block else question.strip()
        fallback_answer = self._build_fallback_answer(tips)

        try:
            contents = self._prepare_messages(history, prompt)
            logger.debug(f"Sending prompt to Gemini: {prompt[:100]}...")
            # Apply safety settings at generation time
            response = self.model.generate_content(
                contents,
                safety_settings=self.safety_settings
            )
            
            # Log response for debugging
            logger.debug(f"Gemini response status: {getattr(response, 'prompt_feedback', 'N/A')}")
            
            answer = self._extract_response_text(response)
            if not answer:
                self._log_safety_ratings(response)
                self._log_prompt_feedback(response)
                self._log_debug_response(response)
                logger.warning("Gemini returned no textual content. Using fallback knowledge answer.")
                # Use knowledge base as fallback
                answer = fallback_answer
                if not answer:
                    answer = "Xin lỗi, tôi không thể xử lý câu hỏi của bạn lúc này. Vui lòng thử lại sau."
        except Exception as exc:
            logger.exception("Gemini gọi API thất bại: %s", exc)
            answer = fallback_answer

        tips_brief = [
            {
                "id": tip.get("id", ""),
                "title": tip.get("title", ""),
                "summary": tip.get("summary", ""),
            }
            for tip in tips
        ]

        return {"answer": answer, "tips": tips_brief}
