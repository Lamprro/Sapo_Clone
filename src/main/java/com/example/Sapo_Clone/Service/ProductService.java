package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Product.ChangeProductStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Product.ProductInventoryResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductReportDetailResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductReportProjection;
import com.example.Sapo_Clone.DTO.Response.Product.ProductResponse;
import org.springframework.data.domain.Page;

import java.util.List;

public interface ProductService {

    ProductResponse createProduct(ProductCreateDTO dto);

    ProductResponse getProductByIdForCustomer(int productId);

    ProductResponse getProductByIdForManage(int productId);

    Page<ProductResponse> getList(String keyword, List<Integer> categoryIds, int page, int size);

    ProductResponse updateProduct(int productId, ProductUpdateDTO dto);

    ProductResponse changeStatus(int productId, ChangeProductStatusDTO dto);

    ProductInventoryResponse getProductInventory(int productId, int storeId);

    Page<ProductResponse> getProductsByStore(int page, int size);

    List<ProductReportProjection> getReportAll();

    ProductReportDetailResponse getReportByProduct(int productId, int page, int size);
}